#!/bin/sh
set -e

ZT_HOME=/data/xnet
PORTAL_DATA=/data/portal

mkdir -p "$ZT_HOME" "$PORTAL_DATA"

# Replace stock planet with mars if available
if [ -f "$ZT_HOME/mars" ]; then
  cp "$ZT_HOME/mars" "$ZT_HOME/planet"
  echo "[xnet] Planet replaced with mars"
fi

# Start xnet daemon
xnet-one "$ZT_HOME" &

# Start speed test server
xnet-speed 19980 &

# Wait for API
echo "[xnet] Waiting for xnet-one..."
until [ -f "$ZT_HOME/authtoken.secret" ] && wget -qO /dev/null --header "X-ZT1-Auth: $(cat $ZT_HOME/authtoken.secret)" http://127.0.0.1:9993/status 2>/dev/null; do
  sleep 1
done
echo "[xnet] xnet-one ready"

# Copy auth token for portal
cp "$ZT_HOME/authtoken.secret" "$PORTAL_DATA/authtoken.secret"

# Auto-join own networks
TOKEN=$(cat "$ZT_HOME/authtoken.secret")
for NWID in $(wget -qO- --header "X-ZT1-Auth: $TOKEN" http://127.0.0.1:9993/controller/network 2>/dev/null | tr -d '[]"' | tr ',' '\n'); do
  xnet-cli -D"$ZT_HOME" join "$NWID" >/dev/null 2>&1 && echo "[xnet] Joined $NWID"
done

# NAT gateway for ZT clients
DEFAULT_IF=$(ip route show default | awk '{print $5}' | head -1)
if [ -n "$DEFAULT_IF" ]; then
  iptables -t nat -A POSTROUTING -o "$DEFAULT_IF" -s 10.121.21.0/24 -j MASQUERADE 2>/dev/null
  iptables -A FORWARD -i zte+ -o "$DEFAULT_IF" -j ACCEPT 2>/dev/null
  iptables -A FORWARD -i "$DEFAULT_IF" -o zte+ -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null
  echo "[xnet] NAT gateway enabled on $DEFAULT_IF"
fi

# Start portal
exec java -jar /opt/portal.jar 3001 "$PORTAL_DATA"
