#!/data/data/com.termux/files/usr/bin/sh
# Boot the DSH web surface inside the proot container.
# Kept separate from dsh-start.sh so it can also be run by hand for debugging.

DISTRO="${DSH_DISTRO:-debian}"

exec "${PREFIX:-/data/data/com.termux/files/usr}/bin/proot-distro" login "${DISTRO}" -- /bin/sh -c 'export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin; cd /root; exec dsh web --no-open --host 127.0.0.1 --port 3080'
