#!/bin/bash

# Default values
DEFAULT_PROTOCOL="vmess"
DEFAULT_ADDRESS="13.61.107.102"
DEFAULT_PORT="58073"
DEFAULT_UUID="72a8f934-48f4-487c-9bbf-5fd64918a7c8"
DEFAULT_SOCKS_PORT="1089"
DEFAULT_TIMEZONE="America/New_York"

# Store original timezone
ORIGINAL_TIMEZONE=$(cat /etc/timezone)

# Script usage
usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  install              Install v2ray and dependencies"
    echo "  connect              Configure and connect to VPN"
    echo "  disconnect           Disconnect VPN and reset configuration"
    echo ""
    echo "Options:"
    echo "  -p, --protocol      Protocol (default: $DEFAULT_PROTOCOL)"
    echo "  -a, --address       Server address (default: $DEFAULT_ADDRESS)"
    echo "  -P, --port          Server port (default: $DEFAULT_PORT)"
    echo "  -u, --uuid          UUID (default: $DEFAULT_UUID)"
    echo "  -s, --socks-port    Local SOCKS port (default: $DEFAULT_SOCKS_PORT)"
    echo "  -t, --timezone      Timezone (default: $DEFAULT_TIMEZONE)"
    echo "  -h, --help          Show this help message"
    exit 1
}

# Check for root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Please run with sudo"
        exit 1
    fi
}

# Backup iptables rules
backup_iptables() {
    echo "Backing up current iptables rules..."
    iptables-save >/etc/iptables.backup
}

# Restore iptables rules
restore_iptables() {
    if [ -f /etc/iptables.backup ]; then
        echo "Restoring iptables rules..."
        iptables-restore </etc/iptables.backup
        rm /etc/iptables.backup
    fi
}

# Start v2ray process
start_v2ray() {
    echo "Starting v2ray..."

    # Kill any existing v2ray process
    systemctl stop v2ray || true
    pkill v2ray || true
    sleep 1

    # Start v2ray service
    systemctl start v2ray
    sleep 2

    # Verify it's running
    if ! systemctl is-active v2ray >/dev/null 2>&1; then
        echo "Failed to start v2ray. Check logs:"
        journalctl -u v2ray --no-pager -n 50
        return 1
    fi

    # Test connection
    echo "Testing connection..."
    if ! curl -s --max-time 5 -x socks5h://127.0.0.1:$SOCKS_PORT ifconfig.me >/dev/null; then
        echo "Connection test failed. V2Ray logs:"
        journalctl -u v2ray --no-pager -n 50
        return 1
    fi

    echo "V2Ray started successfully"
    return 0
}

# Stop v2ray process
stop_v2ray() {
    echo "Stopping v2ray..."
    systemctl stop v2ray
    sleep 1
}

# Install v2ray and dependencies
install_v2ray() {
    check_root

    echo "Installing v2ray and dependencies..."

    # Update package lists
    apt update

    # Pre-configure iptables-persistent to skip prompt
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

    # Install required packages
    apt install -y curl wget unzip daemon iptables iptables-persistent

    # Create iptables rules directory
    mkdir -p /etc/iptables

    # Download and run official v2ray install script
    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

    # Install v2ray rules/geo data
    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh)

    echo "Installation completed successfully"
}

# Configure and connect to VPN
configure_and_connect() {
    check_root

    # Backup and change timezone
    echo "Changing timezone to $TIMEZONE..."
    echo $ORIGINAL_TIMEZONE >/tmp/original_timezone
    timedatectl set-timezone $TIMEZONE

    echo "Configuring v2ray..."

    # Create v2ray config
    cat >/usr/local/etc/v2ray/config.json <<EOF
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "info"
  },
  "inbounds": [{
    "port": $SOCKS_PORT,
    "listen": "127.0.0.1",
    "protocol": "socks",
    "settings": {
      "udp": true
    }
  }],
  "outbounds": [{
    "protocol": "$PROTOCOL",
    "settings": {
      "vnext": [{
        "address": "$ADDRESS",
        "port": $PORT,
        "users": [{
          "id": "$UUID",
          "alterId": 0,
          "security": "auto"
        }]
      }]
    }
  }]
}
EOF

    # Create log directory if it doesn't exist
    mkdir -p /var/log/v2ray
    chown -R v2ray:v2ray /var/log/v2ray

    # Start v2ray with new config
    if ! start_v2ray; then
        echo "Failed to start v2ray"
        exit 1
    fi

    # Configure kill switch using iptables
    echo "Setting up kill switch..."

    # Backup current iptables rules
    backup_iptables

    # Clear existing rules
    iptables -F
    iptables -X

    # Set default policies
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP

    # Allow loopback traffic
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT

    # Allow ICMP (ping)
    iptables -A INPUT -p icmp -j ACCEPT
    iptables -A OUTPUT -p icmp -j ACCEPT

    # Allow DNS
    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT

    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

    # Allow outbound traffic to VPN server
    iptables -A OUTPUT -d $ADDRESS -j ACCEPT

    # Allow common development ports
    iptables -A OUTPUT -p tcp -m multiport --dports 22,80,443 -j ACCEPT
    iptables -A OUTPUT -p tcp --match multiport --dports 3000:3999 -j ACCEPT
    iptables -A OUTPUT -p tcp --match multiport --dports 5000:5999 -j ACCEPT
    iptables -A OUTPUT -p tcp --match multiport --dports 8000:8999 -j ACCEPT

    # Save iptables rules for persistence
    mkdir -p /etc/iptables
    if command -v netfilter-persistent >/dev/null 2>&1; then
        netfilter-persistent save
    else
        iptables-save >/etc/iptables/rules.v4
    fi

    echo "Setting up system-wide proxy..."
    # Set system-wide proxy environment variables
    cat >/etc/profile.d/proxy.sh <<EOF
export http_proxy="socks5://127.0.0.1:$SOCKS_PORT"
export https_proxy="socks5://127.0.0.1:$SOCKS_PORT"
export all_proxy="socks5://127.0.0.1:$SOCKS_PORT"
EOF

    chmod +x /etc/profile.d/proxy.sh

    echo "VPN configured and connected. Testing final connection..."
    curl -x socks5h://127.0.0.1:$SOCKS_PORT ifconfig.me
}

# Disconnect and reset configuration
disconnect_and_reset() {
    check_root

    # Restore original timezone
    if [ -f /tmp/original_timezone ]; then
        ORIG_TZ=$(cat /tmp/original_timezone)
        echo "Restoring timezone to $ORIG_TZ..."
        timedatectl set-timezone $ORIG_TZ
        rm /tmp/original_timezone
    fi

    # Stop v2ray
    stop_v2ray

    # Remove system-wide proxy
    rm -f /etc/profile.d/proxy.sh

    # Restore original iptables rules
    restore_iptables

    echo "Disconnected and reset successfully"
}

# Parse command line arguments
COMMAND=""
PROTOCOL=$DEFAULT_PROTOCOL
ADDRESS=$DEFAULT_ADDRESS
PORT=$DEFAULT_PORT
UUID=$DEFAULT_UUID
SOCKS_PORT=$DEFAULT_SOCKS_PORT
TIMEZONE=$DEFAULT_TIMEZONE

while [[ $# -gt 0 ]]; do
    case $1 in
    install | connect | disconnect)
        COMMAND=$1
        shift
        ;;
    -p | --protocol)
        PROTOCOL=$2
        shift 2
        ;;
    -a | --address)
        ADDRESS=$2
        shift 2
        ;;
    -P | --port)
        PORT=$2
        shift 2
        ;;
    -u | --uuid)
        UUID=$2
        shift 2
        ;;
    -s | --socks-port)
        SOCKS_PORT=$2
        shift 2
        ;;
    -t | --timezone)
        TIMEZONE=$2
        shift 2
        ;;
    -h | --help)
        usage
        ;;
    *)
        echo "Unknown option: $1"
        usage
        ;;
    esac
done

# Execute command
case $COMMAND in
install)
    install_v2ray
    ;;
connect)
    configure_and_connect
    ;;
disconnect)
    disconnect_and_reset
    ;;
*)
    usage
    ;;
esac
