#!/bin/sh
set -e

ZT_HOME=/data/zerotier
PORTAL_DATA=/data/portal

mkdir -p "$ZT_HOME" "$PORTAL_DATA"

# Replace stock planet with mars if available
if [ -f "$ZT_HOME/mars" ]; then
  cp "$ZT_HOME/mars" "$ZT_HOME/planet"
  echo "[xnet] Planet replaced with mars"
fi

# Start ZeroTier
zerotier-one "$ZT_HOME" &
ZT_PID=$!

# Wait for ZT API
echo "[xnet] Waiting for ZeroTier..."
until [ -f "$ZT_HOME/authtoken.secret" ] && wget -qO /dev/null --header "X-ZT1-Auth: $(cat $ZT_HOME/authtoken.secret)" http://127.0.0.1:9993/status 2>/dev/null; do
  sleep 1
done
echo "[xnet] ZeroTier ready"

# Copy auth token for portal
cp "$ZT_HOME/authtoken.secret" "$PORTAL_DATA/authtoken.secret"

# Auto-join own networks
TOKEN=$(cat "$ZT_HOME/authtoken.secret")
for NWID in $(wget -qO- --header "X-ZT1-Auth: $TOKEN" http://127.0.0.1:9993/controller/network 2>/dev/null | tr -d '[]"' | tr ',' '\n'); do
  zerotier-cli -D"$ZT_HOME" join "$NWID" >/dev/null 2>&1 && echo "[xnet] Joined $NWID"
done

# Start portal
exec java -jar /opt/portal.jar 3001 "$PORTAL_DATA"
