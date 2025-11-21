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

1. **Install Python dependencies:**
   ```bash
   pip install requests
   ```

2. **Ensure files are in place:**
   - `agent.py` should be in `/srv/sr/scripts/tmate_ota/`
   - `config.json` should be in `/srv/sr/scripts/tmate_ota/`

3. **Install and enable the systemd service:**
   ```bash
   sudo cp sr_tmate_ota.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable sr-tmate-ota
   ```

4. **Configure the agent:**
   ```bash
   sudo nano /srv/sr/scripts/tmate_ota/config.json
   ```
   
   Update at minimum:
   - `server_url`: Your tmate server URL (e.g., `http://your-server:1777`)
   - `api_key`: Your API key (must match server's API_KEY)

5. **Start the service:**
   ```bash
   sudo systemctl start sr-tmate-ota
   ```

## Configuration

Edit `/srv/sr/scripts/tmate_ota/config.json`:

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
sudo systemctl start sr-tmate-ota

# Stop service
sudo systemctl stop sr-tmate-ota

# Restart service
sudo systemctl restart sr-tmate-ota

# Check status
sudo systemctl status sr-tmate-ota

# View logs
sudo journalctl -u sr-tmate-ota -f

# View log file
sudo tail -f /var/log/tmate-client/agent.log

# Disable on boot
sudo systemctl disable sr-tmate-ota
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

2. Check if Python dependencies are installed:
   ```bash
   pip show requests
   ```

3. Check service logs:
   ```bash
   sudo journalctl -u sr-tmate-ota -n 50
   ```

4. Check log file:
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
sudo python3 /srv/sr/scripts/tmate_ota/agent.py
```

Or with custom config:

```bash
sudo TMATE_CLIENT_CONFIG=/path/to/config.json python3 /srv/sr/scripts/tmate_ota/agent.py
```

## Uninstallation

```bash
sudo systemctl stop sr-tmate-ota
sudo systemctl disable sr-tmate-ota
sudo rm /etc/systemd/system/sr_tmate_ota.service
sudo systemctl daemon-reload
sudo rm -rf /var/log/tmate-client
```

## Security Notes

- The service runs as root by default (required for system-level operations)
- API key is stored in plain text in config file (protect with proper file permissions)
- Consider using environment variables for sensitive data
- The tmate socket is created in /tmp (world-writable by default)


