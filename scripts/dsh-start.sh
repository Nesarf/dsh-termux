#!/data/data/com.termux/files/usr/bin/sh
# Start dsh web inside the container, wait for the token URL, then open the
# default Android browser on the 3081 bridge (which redirects to the token URL).

H="${HOME:-/data/data/com.termux/files/home}"
T="${PREFIX:-/data/data/com.termux/files/usr}/bin"

cd "$H" || exit 1

# dsh web (3080): reuse a running instance instead of starting a second one.
if ! "$T/fuser" 3080/tcp >/dev/null 2>&1; then
  nohup "$H/dsh-web.sh" > ./dsh-web.log 2>&1 &
fi

# 302 bridge (3081): redirects a bare localhost URL to the current token URL.
if ! "$T/fuser" 3081/tcp >/dev/null 2>&1; then
  DSH_WEB_LOG="$H/dsh-web.log" nohup "$T/node" "$H/dsh-open-302.js" > ./dsh-open.log 2>&1 &
  sleep 1
fi

i=0
U=
while [ "$i" -lt 120 ]; do
  U=$(grep -o 'http://127.0.0.1:3080/[^ ]*' ./dsh-web.log 2>/dev/null | head -1)
  [ -n "$U" ] && break
  sleep 1
  i=$((i+1))
done

if [ -n "$U" ]; then
  "$T/termux-open-url" "http://127.0.0.1:3081/"
else
  echo "dsh web: no token URL after 120s; check $H/dsh-web.log"
fi
