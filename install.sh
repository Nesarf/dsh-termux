#!/data/data/com.termux/files/usr/bin/sh
# Install DeepSeek Harness inside a proot Debian container on Termux.
# Run from Termux, not from inside the container.

set -e

DSH_VERSION="${DSH_VERSION:-0.2.1-rc.2}"
DSH_DISTRO="${DSH_DISTRO:-debian}"
DSH_REGISTRY="${DSH_REGISTRY:-}"
NODE_MIN_MAJOR="${NODE_MIN_MAJOR:-22}"

log() { printf '%s\n' "$*"; }
die() { printf '%s\n' "$*" >&2; exit 1; }

command -v proot-distro >/dev/null 2>&1 || die "proot-distro not found; run: pkg install proot-distro"

if ! proot-distro list 2>/dev/null | grep -Eq "^[[:space:]]*\*[[:space:]]+${DSH_DISTRO}$"; then
  log "installing distro: ${DSH_DISTRO}"
  proot-distro install "${DSH_DISTRO}"
fi

REGISTRY_LINE=""
if [ -n "${DSH_REGISTRY}" ]; then
  REGISTRY_LINE="npm config set registry '${DSH_REGISTRY}' &&"
fi

log "installing @deepseek-ai/dsh@${DSH_VERSION} inside ${DSH_DISTRO}"
proot-distro login "${DSH_DISTRO}" -- /bin/sh -c "
set -e
if ! command -v node >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y nodejs npm
fi
node -v
major=\$(node -v | sed 's/^v//' | cut -d. -f1)
if [ \"\$major\" -lt ${NODE_MIN_MAJOR} ]; then
  echo \"node >= ${NODE_MIN_MAJOR} is required by @deepseek-ai/dsh@${DSH_VERSION}\" >&2
  exit 1
fi
$REGISTRY_LINE npm i -g @deepseek-ai/dsh@${DSH_VERSION}
dsh --version
"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
log "installing launcher scripts into ${HOME}"
for f in dsh-web.sh dsh-open-302.js dsh-start.sh dsh-restart.sh; do
  cp "${SCRIPT_DIR}/scripts/$f" "${HOME}/$f"
  chmod 755 "${HOME}/$f"
done

if [ -n "${DEEPSEEK_API_KEY:-}" ]; then
  log "storing DEEPSEEK_API_KEY in the container"
  proot-distro login "${DSH_DISTRO}" -- /bin/sh -c "
mkdir -p /root/.dsh
printf 'version: 1\nrefs:\n  DEEPSEEK_API_KEY: %s\n' '${DEEPSEEK_API_KEY}' > /root/.dsh/.credentials.yaml
chmod 600 /root/.dsh/.credentials.yaml
"
else
  log "no DEEPSEEK_API_KEY given; write /root/.dsh/.credentials.yaml inside the container or set the key in the Web UI Models page"
fi

log ""
log "done. start it with:  ~/dsh-start.sh"
log "restart with:         ~/dsh-restart.sh"
