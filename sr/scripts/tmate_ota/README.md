# tmate Client Agent

A system service that automatically creates tmate sessions on boot and reports them to the tmate server.

## Features

- ✅ Creates tmate session automatically on boot
- ✅ Probes server health periodically
- ✅ Sends session details to server when server is active
- ✅ Auto-recreates session if it dies
- ✅ Runs as systemd service
- ✅ Configurable via JSON config file

## Prerequisites

1. **tmate** must be installed:
   ```bash
   # Ubuntu/Debian
   sudo apt-get install tmate
   
   # RHEL/CentOS
   sudo yum install tmate
   
   # Or build from source
   git clone https://github.com/tmate-io/tmate.git
   cd tmate
   ./create-release.sh
   ```

2. **Python 3.6+** with pip

3. **Network access** to the tmate server

## Installation

1. **Run the installation script:**
   ```bash
   cd client
   sudo ./install.sh
   ```

2. **Configure the agent:**
   ```bash
   sudo nano /etc/tmate-client/config.json
   ```
   
   Update at minimum:
   - `server_url`: Your tmate server URL (e.g., `http://your-server:1777`)
   - `api_key`: Your API key (must match server's API_KEY)

3. **Start the service:**
   ```bash
   sudo systemctl start tmate-client
   sudo systemctl enable tmate-client  # Enable on boot
   ```

## Configuration

Edit `/etc/tmate-client/config.json`:

```json
{
  "server_url": "http://your-server:1777",
  "api_key": "your-api-key",
  "device_id": null,
  "probe_interval": 30,
  "health_check_interval": 10,
  "tmate_command": "tmate",
  "tmate_args": ["-S", "/tmp/tmate.sock", "new-session", "-d"]
}
```

### Configuration Options

- `server_url`: Full URL of the tmate server (including port)
- `api_key`: API key for authentication (must match server config)
- `device_id`: Device identifier (null = auto-generate from /etc/machine-id or UUID)
- `probe_interval`: Seconds between sending session info to server (default: 30)
- `health_check_interval`: Seconds between server health checks (default: 10)
- `tmate_command`: Path to tmate executable (default: "tmate")
- `tmate_args`: Arguments passed to tmate (default: creates detached session)

## Service Management

```bash
# Start service
sudo systemctl start tmate-client

# Stop service
sudo systemctl stop tmate-client

# Restart service
sudo systemctl restart tmate-client

# Check status
sudo systemctl status tmate-client

# View logs
sudo journalctl -u tmate-client -f

# View log file
sudo tail -f /var/log/tmate-client/agent.log

# Disable on boot
sudo systemctl disable tmate-client
```

## How It Works

1. **On Boot**: Service starts and immediately creates a tmate session
2. **Health Check**: Every 10 seconds (configurable), checks if server is reachable
3. **Session Reporting**: When server is active, sends session info every 30 seconds (configurable)
4. **Auto-Recovery**: If tmate session dies, automatically recreates it
5. **Continuous Operation**: Runs indefinitely, maintaining connection to server

## Troubleshooting

### Service won't start

1. Check if tmate is installed:
   ```bash
   which tmate
   tmate --version
   ```

2. Check service logs:
   ```bash
   sudo journalctl -u tmate-client -n 50
   ```

3. Check log file:
   ```bash
   sudo cat /var/log/tmate-client/agent.log
   ```

### Can't connect to server

1. Verify server is running:
   ```bash
   curl http://your-server:1777/health
   ```

2. Check network connectivity:
   ```bash
   ping your-server
   ```

3. Verify API key matches server configuration

### tmate session not created

1. Check if tmate socket exists:
   ```bash
   ls -la /tmp/tmate.sock
   ```

2. Test tmate manually:
   ```bash
   tmate -S /tmp/tmate.sock new-session -d
   tmate -S /tmp/tmate.sock display -p '#{tmate_ssh}'
   ```

3. Check permissions (service runs as root by default)

## Manual Testing

You can run the agent manually for testing:

```bash
sudo python3 /opt/tmate-client/agent.py
```

Or with custom config:

```bash
sudo TMATE_CLIENT_CONFIG=/path/to/config.json python3 /opt/tmate-client/agent.py
```

## Uninstallation

```bash
sudo systemctl stop tmate-client
sudo systemctl disable tmate-client
sudo rm /etc/systemd/system/tmate-client.service
sudo systemctl daemon-reload
sudo rm -rf /opt/tmate-client
sudo rm -rf /etc/tmate-client
sudo rm -rf /var/log/tmate-client
```

## Security Notes

- The service runs as root by default (required for system-level operations)
- API key is stored in plain text in config file (protect with proper file permissions)
- Consider using environment variables for sensitive data
- The tmate socket is created in /tmp (world-writable by default)


