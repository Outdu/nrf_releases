cd /srv/sr/initservices
sudo cp sr_* /etc/systemd/system/
sudo usermod -aG audio sr
sudo systemctl disable sr_shutdown.timer
