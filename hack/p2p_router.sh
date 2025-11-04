#!/usr/bin/env bash
# p2p_link.sh — DHCP/IPv4 for a single peer-to-peer Ethernet link (no NAT, no routing)
set -euo pipefail

LAN_IF="enp0s13f0u3"      # the cable interface to the other computer
LAN_CIDR="192.168.100.1/24"
DHCP=0                    # enable with --dhcp

ACTION="${1:-}"; shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --lan)  LAN_IF="$2"; shift 2;;
    --cidr) LAN_CIDR="$2"; shift 2;;
    --dhcp) DHCP=1; shift;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

need_root(){ [[ $EUID -eq 0 ]] || { echo "Run as root." >&2; exit 1; }; }

# --- small IP helpers (no external deps) ---
ip_to_int(){ IFS=. read -r a b c d <<<"$1"; echo $(( (a<<24)+(b<<16)+(c<<8)+d )); }
int_to_ip(){ local x=$1; printf "%d.%d.%d.%d" $(( (x>>24)&255 )) $(( (x>>16)&255 )) $(( (x>>8)&255 )) $(( x&255 )); }
prefix_to_mask(){ local p=$1; local m=$(( 0xFFFFFFFF << (32-p) & 0xFFFFFFFF )); int_to_ip "$m"; }
network_of(){ local ip=$1 mask=$2; local n=$(( $(ip_to_int "$ip") & $(ip_to_int "$mask") )); int_to_ip "$n"; }
broadcast_of(){ local ip=$1 mask=$2; local n=$(ip_to_int "$(network_of "$ip" "$mask")"); local inv=$(( 0xFFFFFFFF ^ $(ip_to_int "$mask") )); int_to_ip $(( n | inv )); }

calc_dhcp_range(){
  local ip=$1 prefix=$2
  local mask net bcast ni bi start end first last
  mask=$(prefix_to_mask "$prefix")
  net=$(network_of "$ip" "$mask")
  bcast=$(broadcast_of "$ip" "$mask")
  ni=$(ip_to_int "$net"); bi=$(ip_to_int "$bcast")
  first=$((ni+2)); last=$((bi-2))
  start=$(( ni + 50 )); end=$(( ni + 150 ))
  [[ $start -lt $first ]] && start=$first
  [[ $end   -gt $last  ]] && end=$last
  echo "$(int_to_ip $start) $(int_to_ip $end) $mask"
}

start() {
  need_root

  # bring link up with static IP
  ip link set "$LAN_IF" up
  ip addr show dev "$LAN_IF" | grep -q "$LAN_CIDR" || ip addr add "$LAN_CIDR" dev "$LAN_IF"

  # parse LAN_CIDR
  local LAN_IP="${LAN_CIDR%/*}"
  local LAN_PREFIX="${LAN_CIDR#*/}"
  local LAN_MASK; LAN_MASK=$(prefix_to_mask "$LAN_PREFIX")

  # nftables: only allow DHCP to the host (no forward, no NAT)
  nft -f - <<EOF
table inet p2p {
  chain input {
    type filter hook input priority 0; policy accept;
    # be explicit for DHCP on the LAN (helps with stricter host firewalls)
    ip protocol udp iifname "$LAN_IF" udp dport 67 accept
    ip protocol udp iifname "$LAN_IF" udp dport 68 accept
  }
}
EOF

  # Optional DHCP server for the peer
  if [[ "$DHCP" -eq 1 ]]; then
    command -v dnsmasq >/dev/null || { echo "dnsmasq not found." >&2; exit 1; }
    read -r DHCP_START DHCP_END DHCP_MASK <<<"$(calc_dhcp_range "$LAN_IP" "$LAN_PREFIX")"
    mkdir -p /run/p2p-router
    cat > /run/p2p-router/dnsmasq.conf <<CONF
port=0
interface=${LAN_IF}
bind-dynamic
dhcp-authoritative
dhcp-broadcast
dhcp-range=${DHCP_START},${DHCP_END},${DHCP_MASK},12h
dhcp-option=option:router,${LAN_IP}
dhcp-option=option:dns-server,1.1.1.1,9.9.9.9
log-dhcp
log-facility=/run/p2p-router/dnsmasq.log
dhcp-leasefile=/run/p2p-router/dnsmasq.leases
pid-file=/run/p2p-router/dnsmasq.pid
CONF
    # (re)start dnsmasq instance
    [[ -f /run/p2p-router/dnsmasq.pid ]] && kill "$(cat /run/p2p-router/dnsmasq.pid)" 2>/dev/null || true
    dnsmasq --conf-file=/run/p2p-router/dnsmasq.conf
    echo "DHCP on $LAN_IF: $DHCP_START – $DHCP_END (mask $DHCP_MASK), router $LAN_IP."
  fi

  echo "Peer-to-peer link up on $LAN_IF ($LAN_CIDR). No NAT, no inter-iface routing."
}

stop() {
  need_root
  if [[ -f /run/p2p-router/dnsmasq.pid ]]; then
    kill "$(cat /run/p2p-router/dnsmasq.pid)" || true
    rm -f /run/p2p-router/dnsmasq.pid
    echo "DHCP stopped."
  fi
  nft list table inet p2p >/dev/null 2>&1 && nft delete table inet p2p || true
  ip addr del "$LAN_CIDR" dev "$LAN_IF" 2>/dev/null || true
  echo "Cleaned up."
}

usage() {
  cat <<USAGE
Usage:
  sudo $0 start [--lan IFACE] [--cidr IP/PREFIX] [--dhcp]
  sudo $0 stop

Example:
  sudo $0 start --lan enp0s13f0u3 --cidr 192.168.100.1/24 --dhcp
USAGE
}

case "${ACTION}" in
  start) start ;;
  stop)  stop ;;
  *) usage; exit 1;;
esac
