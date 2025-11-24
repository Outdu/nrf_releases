#!/usr/bin/env python3
"""
tmate Client Agent
Creates tmate sessions on boot and reports to server
"""
import subprocess
import time
import logging
import socket
import uuid
import platform
import requests
import json
import os
import sys
from pathlib import Path
from typing import Optional, Dict, Any
from datetime import datetime

# Setup logging
log_dir = Path("/var/log/tmate-client")
log_dir.mkdir(parents=True, exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(log_dir / "agent.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class TmateAgent:
    def __init__(self, config_path: str = "/srv/sr/scripts/tmate_ota/config.json"):
        self.config = self.load_config(config_path)
        self.device_id = self.get_device_id()
        self.agent_version = "1.0.0"
        self.tmate_process: Optional[subprocess.Popen] = None
        self.current_session: Optional[Dict[str, str]] = None
        
    def load_config(self, config_path: str) -> Dict[str, Any]:
        """Load configuration from file or use defaults"""
        default_config = {
            "server_url": os.getenv("TMATE_SERVER_URL", "http://localhost:1777"),
            "api_key": os.getenv("TMATE_API_KEY", "outdu-security-key"),
            "client_name": None,  # Optional client name
            "device_id": None,  # Will be generated if not set
            "probe_interval": 30,  # seconds
            "health_check_interval": 10,  # seconds
            "tmate_command": "tmate",
            "tmate_args": ["-S", "/tmp/tmate.sock", "new-session", "-d"]
        }
        
        if os.path.exists(config_path):
            try:
                with open(config_path, 'r') as f:
                    file_config = json.load(f)
                    default_config.update(file_config)
                logger.info(f"Loaded config from {config_path}")
            except Exception as e:
                logger.warning(f"Failed to load config from {config_path}: {e}. Using defaults.")
        else:
            logger.info(f"Config file not found at {config_path}. Using defaults.")
        
        return default_config
    
    def get_device_id(self) -> str:
        """Get or generate device ID"""
        if self.config.get("device_id"):
            return self.config["device_id"]
        
        # Try to get from /etc/machine-id (Linux)
        machine_id_path = Path("/etc/machine-id")
        if machine_id_path.exists():
            try:
                with open(machine_id_path, 'r') as f:
                    machine_id = f.read().strip()
                    if machine_id:
                        return machine_id[:64]  # Limit to 64 chars
            except Exception as e:
                logger.warning(f"Failed to read machine-id: {e}")
        
        # Fallback: generate UUID
        device_id = str(uuid.uuid4())
        logger.info(f"Generated new device ID: {device_id}")
        return device_id
    
    def check_tmate_installed(self) -> bool:
        """Check if tmate is installed"""
        try:
            # Try -V flag (tmate uses -V, not --version)
            result = subprocess.run(
                [self.config["tmate_command"], "-V"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                version_info = result.stdout.strip() or result.stderr.strip()
                logger.info(f"tmate found: {version_info}")
                return True
            # If -V fails, try just running tmate to see if it exists
            result = subprocess.run(
                [self.config["tmate_command"]],
                capture_output=True,
                text=True,
                timeout=5
            )
            # tmate without args returns non-zero but shows usage, so command exists
            logger.info(f"tmate found at: {self.config['tmate_command']}")
            return True
        except FileNotFoundError:
            logger.error(f"tmate not found in PATH: {self.config['tmate_command']}")
        except Exception as e:
            logger.error(f"Error checking tmate: {e}")
        return False
    
    def get_system_info(self) -> Dict[str, Any]:
        """Get system information"""
        hostname = socket.gethostname()
        primary_ip = None
        
        try:
            # Get primary IP (first non-loopback IPv4)
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            primary_ip = s.getsockname()[0]
            s.close()
        except Exception as e:
            logger.warning(f"Failed to get primary IP: {e}")
        
        return {
            "hostname": hostname,
            "primary_ip": primary_ip,
            "platform": platform.platform(),
            "system": platform.system(),
            "release": platform.release()
        }
    
    def create_tmate_session(self) -> Optional[Dict[str, str]]:
        """Create a new tmate session and extract connection strings"""
        try:
            # Kill any existing tmate session
            self.kill_tmate_session()
            
            # Create new tmate session
            logger.info("Creating new tmate session...")
            self.tmate_process = subprocess.Popen(
                [self.config["tmate_command"]] + self.config["tmate_args"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Wait for process to complete (for detached sessions, process exits after creating session)
            self.tmate_process.wait(timeout=10)
            # Clear process reference since it's completed (session continues running)
            self.tmate_process = None
            
            # Wait a bit for session to establish
            time.sleep(2)
            
            # Get session info from tmate
            session_info = self.get_tmate_session_info()
            
            if session_info and session_info.get("ssh") and session_info.get("web"):
                self.current_session = session_info
                logger.info(f"tmate session created - SSH: {session_info['ssh']}")
                logger.info(f"tmate session created - WEB: {session_info['web']}")
                return session_info
            else:
                logger.error("Failed to get tmate session info")
                return None
                
        except Exception as e:
            logger.error(f"Failed to create tmate session: {e}")
            return None
    
    def get_tmate_session_info(self) -> Optional[Dict[str, str]]:
        """Extract SSH and WEB connection strings from tmate"""
        try:
            # Use tmate -S /tmp/tmate.sock display -p '#{tmate_ssh}' to get SSH string
            ssh_result = subprocess.run(
                [self.config["tmate_command"], "-S", "/tmp/tmate.sock", 
                 "display", "-p", "#{tmate_ssh}"],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            web_result = subprocess.run(
                [self.config["tmate_command"], "-S", "/tmp/tmate.sock",
                 "display", "-p", "#{tmate_web}"],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            ssh_fingerprint_result = subprocess.run(
                [self.config["tmate_command"], "-S", "/tmp/tmate.sock",
                 "display", "-p", "#{tmate_ssh_fingerprint}"],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            ssh = ssh_result.stdout.strip() if ssh_result.returncode == 0 else None
            web = web_result.stdout.strip() if web_result.returncode == 0 else None
            ssh_fingerprint = ssh_fingerprint_result.stdout.strip() if ssh_fingerprint_result.returncode == 0 else None
            
            if ssh and web:
                return {
                    "ssh": ssh,
                    "web": web,
                    "ssh_fingerprint": ssh_fingerprint
                }
        except Exception as e:
            logger.error(f"Failed to get tmate session info: {e}")
        
        return None
    
    def kill_tmate_session(self):
        """Kill existing tmate session"""
        try:
            if self.tmate_process:
                self.tmate_process.terminate()
                self.tmate_process.wait(timeout=5)
                self.tmate_process = None
        except Exception as e:
            logger.warning(f"Error killing tmate process: {e}")
        
        # Also try to kill via socket
        try:
            subprocess.run(
                [self.config["tmate_command"], "-S", "/tmp/tmate.sock", "kill-session"],
                capture_output=True,
                timeout=5
            )
        except Exception:
            pass
    
    def check_internet_connectivity(self) -> bool:
        """Check if internet connectivity is available"""
        try:
            # Try to connect to a reliable DNS server (Google DNS)
            socket.create_connection(("8.8.8.8", 53), timeout=3)
            return True
        except OSError:
            try:
                # Fallback: try Cloudflare DNS
                socket.create_connection(("1.1.1.1", 53), timeout=3)
                return True
            except OSError:
                logger.debug("Internet connectivity check failed")
                return False
    
    def check_server_health(self) -> bool:
        """Check if server is reachable"""
        try:
            health_url = f"{self.config['server_url']}/health"
            response = requests.get(health_url, timeout=5)
            if response.status_code == 200:
                logger.debug("Server health check passed")
                return True
        except requests.exceptions.RequestException as e:
            logger.debug(f"Server health check failed: {e}")
        return False
    
    def send_session_to_server(self, session_info: Dict[str, str]) -> bool:
        """Send tmate session info to server"""
        try:
            sysinfo = self.get_system_info()
            
            payload = {
                "device_id": self.device_id,
                "agent_version": self.agent_version,
                "created_at": int(datetime.utcnow().timestamp()),
                "client_name": self.config.get("client_name"),
                "tmate": {
                    "ssh": session_info.get("ssh"),
                    "web": session_info.get("web"),
                    "ssh_fingerprint": session_info.get("ssh_fingerprint")
                },
                "sys": {
                    "hostname": sysinfo["hostname"],
                    "primary_ip": sysinfo["primary_ip"]
                }
            }
            
            url = f"{self.config['server_url']}/api/v1/session"
            headers = {
                "X-API-Key": self.config["api_key"],
                "Content-Type": "application/json"
            }
            
            response = requests.post(url, json=payload, headers=headers, timeout=10)
            
            if response.status_code in [200, 201]:
                logger.info(f"Successfully sent session info to server: {response.json()}")
                return True
            else:
                logger.error(f"Server returned error: {response.status_code} - {response.text}")
                return False
                
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to send session to server: {e}")
            return False
    
    def run(self):
        """Main run loop"""
        logger.info("Starting tmate agent...")
        logger.info(f"Device ID: {self.device_id}")
        logger.info(f"Server URL: {self.config['server_url']}")
        
        # Check if tmate is installed
        if not self.check_tmate_installed():
            logger.error("tmate is not installed. Please install it first.")
            logger.error("On Ubuntu/Debian: sudo apt-get install tmate")
            logger.error("On RHEL/CentOS: sudo yum install tmate")
            sys.exit(1)
        
        # Create initial tmate session on boot
        logger.info("Creating initial tmate session on boot...")
        session_info = self.create_tmate_session()
        
        if not session_info:
            logger.error("Failed to create initial tmate session")
            sys.exit(1)
        
        # Main loop
        last_health_check = 0
        last_session_send = 0
        
        while True:
            try:
                current_time = time.time()
                
                # Check internet connectivity and server health periodically
                if current_time - last_health_check >= self.config["health_check_interval"]:
                    # First check if internet is available
                    if self.check_internet_connectivity():
                        # Internet is available, check server health
                        if self.check_server_health():
                            # Server is up, send session info
                            if current_time - last_session_send >= self.config["probe_interval"]:
                                logger.info("Internet available and server is active, sending session info...")
                                if self.send_session_to_server(self.current_session or session_info):
                                    last_session_send = current_time
                                else:
                                    logger.warning("Failed to send session info, will retry")
                        else:
                            logger.debug("Internet available but server is not reachable, will retry")
                    else:
                        logger.debug("Internet connectivity not available, skipping server probe")
                    
                    last_health_check = current_time
                
                # Check if tmate session is still alive (check socket, not process)
                # For detached sessions, the process exits but session continues
                socket_path = "/tmp/tmate.sock"
                session_alive = False
                if Path(socket_path).exists():
                    # Try to get session info to verify it's still active
                    test_info = self.get_tmate_session_info()
                    if test_info and test_info.get("ssh") and test_info.get("web"):
                        session_alive = True
                
                if not session_alive:
                    logger.warning("tmate session not active, recreating session...")
                    session_info = self.create_tmate_session()
                    if session_info:
                        self.current_session = session_info
                        # Try to send immediately if internet is available and server is up
                        if self.check_internet_connectivity() and self.check_server_health():
                            self.send_session_to_server(session_info)
                
                time.sleep(1)
                
            except KeyboardInterrupt:
                logger.info("Received interrupt signal, shutting down...")
                break
            except Exception as e:
                logger.error(f"Unexpected error in main loop: {e}", exc_info=True)
                time.sleep(5)
        
        # Cleanup
        logger.info("Shutting down...")
        self.kill_tmate_session()


def main():
    """Entry point"""
    config_path = os.getenv("TMATE_CLIENT_CONFIG", "/srv/sr/scripts/tmate_ota/config.json")
    agent = TmateAgent(config_path)
    agent.run()


if __name__ == "__main__":
    main()

