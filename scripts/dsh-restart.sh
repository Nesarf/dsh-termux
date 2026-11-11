#!/data/data/com.termux/files/usr/bin/sh
# Stop the running dsh web and start it again through dsh-start.sh.
# Two passes on purpose: the command line match covers a normal process tree,
# the port match covers an orphan that a killed proot left behind.

P="${PREFIX:-/data/data/com.termux/files/usr}/bin"
H="${HOME:-/data/data/com.termux/files/home}"

for pid in $("$P/pgrep" -f "node /usr/bin/dsh web"); do
  kill "$pid" 2>/dev/null
done
sleep 2

"$P/fuser" -k 3080/tcp 2>/dev/null
sleep 1

cd "$H" || exit 1
nohup "$H/dsh-start.sh" > ./dsh-start.log 2>&1 &
echo "restarted at $(date)"
