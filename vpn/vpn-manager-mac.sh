#!/bin/bash

# Default values
DEFAULT_PROTOCOL="vmess"
DEFAULT_ADDRESS="13.61.107.102"
DEFAULT_PORT="58073"
DEFAULT_UUID="72a8f934-48f4-487c-9bbf-5fd64918a7c8"
DEFAULT_SOCKS_PORT="1089"
DEFAULT_TIMEZONE="America/New_York"

# Store original timezone
ORIGINAL_TIMEZONE=$(sudo systemsetup -gettimezone | awk '{print $3}')

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

# Check for root and get actual user
check_root_and_user() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Please run with sudo"
        exit 1
    fi

    if [ -z "$SUDO_USER" ]; then
        echo "This script must be run with sudo"
        exit 1
    fi

    ACTUAL_USER=$SUDO_USER

    echo "Running commands as user: $ACTUAL_USER"
}

# Run command as actual user
run_as_user() {
    sudo -u $ACTUAL_USER "$@"
}

# Backup pf rules
backup_pf() {
    echo "Backing up current pf rules..."
    if [ -f /etc/pf.conf ]; then
        cp /etc/pf.conf /etc/pf.conf.backup
    fi
}

# Restore pf rules
restore_pf() {
    if [ -f /etc/pf.conf.backup ]; then
        echo "Restoring pf rules..."
        cp /etc/pf.conf.backup /etc/pf.conf
        rm /etc/pf.conf.backup
        pfctl -f /etc/pf.conf
    fi
}

# Start v2ray process
start_v2ray() {
    echo "Starting v2ray..."

    # Kill any existing v2ray process
    pkill v2ray
    sleep 1

    # Start v2ray in background
    nohup v2ray run -c /usr/local/etc/v2ray/config.json >/usr/local/var/log/v2ray.log 2>&1 &

    # Wait for it to start
    sleep 2

    # Verify it's running
    if ! pgrep v2ray >/dev/null; then
        echo "Failed to start v2ray. Check logs:"
        cat /usr/local/var/log/v2ray.log
        return 1
    fi

    # Test connection
    echo "Testing connection..."
    if ! curl -s --max-time 5 -x socks5h://127.0.0.1:$SOCKS_PORT ifconfig.me >/dev/null; then
        echo "Connection test failed. V2Ray logs:"
        cat /usr/local/var/log/v2ray.log
        return 1
    fi

    echo "V2Ray started successfully"
    return 0
}

# Stop v2ray process
stop_v2ray() {
    echo "Stopping v2ray..."
    pkill v2ray
    sleep 1
}

# Install v2ray and dependencies
install_v2ray() {
    check_root_and_user

    echo "Installing v2ray and dependencies..."

    # Install v2ray using Homebrew as regular user
    run_as_user brew install v2ray

    # Create necessary directories with root privileges
    mkdir -p /usr/local/etc/v2ray
    mkdir -p /usr/local/var/log
    chown -R $ACTUAL_USER:staff /usr/local/etc/v2ray
    chown -R $ACTUAL_USER:staff /usr/local/var/log

    echo "Installation completed successfully"
}

# Configure and connect to VPN
configure_and_connect() {
    check_root_and_user

    # Backup and change timezone
    echo "Changing timezone to $TIMEZONE..."
    echo $ORIGINAL_TIMEZONE >/tmp/original_timezone
    systemsetup -settimezone $TIMEZONE

    echo "Configuring v2ray..."

    # Create v2ray config
    cat >/usr/local/etc/v2ray/config.json <<EOF
{
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

    # Start v2ray with the new config
    if ! start_v2ray; then
        echo "Failed to start v2ray"
        exit 1
    fi

    # Configure system-wide proxy
    echo "Setting up system proxy..."
    networksetup -listallnetworkservices | while read service; do
        if [ "$service" != "An asterisk (*) denotes that a network service is disabled." ]; then
            networksetup -setsocksfirewallproxy "$service" 127.0.0.1 $SOCKS_PORT
            networksetup -setsocksfirewallproxystate "$service" on
        fi
    done

    # Configure kill switch using pf
    echo "Setting up kill switch..."

    # Backup current pf rules
    backup_pf

    # Create new pf rules
    cat >/etc/pf.conf <<EOF
# Allow loopback
set skip on lo0

# Block all traffic by default
block all

# Allow ICMP (ping)
pass out inet proto icmp all
pass in inet proto icmp all

# Allow DNS
pass out proto udp from any to any port 53

# Allow established connections
pass in proto tcp flags S/SA keep state
pass in proto udp all keep state

# Allow outbound traffic to VPN server
pass out proto tcp from any to $ADDRESS port $PORT
pass out proto udp from any to $ADDRESS port $PORT

# Allow common development ports
pass out proto tcp to any port {22, 80, 443}    # SSH, HTTP, HTTPS
pass out proto tcp to any port 3000:3999        # Common dev server ports
pass out proto tcp to any port 5000:5999        # More dev server ports
pass out proto tcp to any port 8000:8999        # Common local server ports

# Allow traffic through VPN interface
pass out on utun+ all
EOF

    # Enable pf and load rules
    pfctl -e
    pfctl -f /etc/pf.conf

    echo "VPN configured and connected. Testing final connection..."
    curl -x socks5h://127.0.0.1:$SOCKS_PORT ifconfig.me
}

# Disconnect and reset configuration
disconnect_and_reset() {
    check_root_and_user

    # Restore original timezone
    if [ -f /tmp/original_timezone ]; then
        ORIG_TZ=$(cat /tmp/original_timezone)
        echo "Restoring timezone to $ORIG_TZ..."
        systemsetup -settimezone $ORIG_TZ
        rm /tmp/original_timezone
    fi

    # Stop v2ray
    stop_v2ray

    # Disable system proxy
    echo "Disabling system proxy..."
    networksetup -listallnetworkservices | while read service; do
        if [ "$service" != "An asterisk (*) denotes that a network service is disabled." ]; then
            networksetup -setsocksfirewallproxystate "$service" off
        fi
    done

    # Restore original pf rules
    restore_pf

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
