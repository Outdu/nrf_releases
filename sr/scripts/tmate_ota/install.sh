#!/bin/bash
# Installation script for tmate client agent

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/tmate-client"
CONFIG_DIR="/etc/tmate-client"
SERVICE_FILE="tmate-client.service"

echo "Installing tmate client agent..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Check if tmate is installed
if ! command -v tmate &> /dev/null; then
    echo "ERROR: tmate is not installed."
    echo "Please install tmate first:"
    echo "  Ubuntu/Debian: sudo apt-get install tmate"
    echo "  RHEL/CentOS:   sudo yum install tmate"
    echo "  Or from source: https://github.com/tmate-io/tmate"
    exit 1
fi

# Create directories
echo "Creating directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p /var/log/tmate-client

# Copy files
echo "Copying files..."
cp "$SCRIPT_DIR/agent.py" "$INSTALL_DIR/"
cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/agent.py"

# Install Python dependencies
echo "Installing Python dependencies..."
if command -v pip3 &> /dev/null; then
    pip3 install -r "$INSTALL_DIR/requirements.txt"
else
    echo "WARNING: pip3 not found. Please install Python dependencies manually:"
    echo "  pip3 install -r $INSTALL_DIR/requirements.txt"
fi

# Setup config file
if [ ! -f "$CONFIG_DIR/config.json" ]; then
    echo "Creating config file..."
    if [ -f "$SCRIPT_DIR/config.json.example" ]; then
        cp "$SCRIPT_DIR/config.json.example" "$CONFIG_DIR/config.json"
        echo "Config file created at $CONFIG_DIR/config.json"
        echo "Please edit it with your server URL and API key:"
        echo "  sudo nano $CONFIG_DIR/config.json"
    else
        echo "Creating default config file..."
        cat > "$CONFIG_DIR/config.json" << EOF
{
  "server_url": "http://localhost:1777",
  "api_key": "outdu-security-key",
  "device_id": null,
  "probe_interval": 30,
  "health_check_interval": 10,
  "tmate_command": "tmate",
  "tmate_args": ["-S", "/tmp/tmate.sock", "new-session", "-d"]
}
EOF
    fi
else
    echo "Config file already exists at $CONFIG_DIR/config.json"
fi

# Install systemd service
echo "Installing systemd service..."
cp "$SCRIPT_DIR/$SERVICE_FILE" /etc/systemd/system/
systemctl daemon-reload
systemctl enable tmate-client.service

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Edit the config file: sudo nano $CONFIG_DIR/config.json"
echo "2. Set your server URL and API key"
echo "3. Start the service: sudo systemctl start tmate-client"
echo "4. Check status: sudo systemctl status tmate-client"
echo "5. View logs: sudo journalctl -u tmate-client -f"
echo ""


