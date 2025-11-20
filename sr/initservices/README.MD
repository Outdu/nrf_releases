cd /srv/sr/initservices
sudo cp sr_* /etc/systemd/system/
sudo systemctl enable sr_*
sudo usermod -aG audio sr
sudo systemctl disable sr_shutdown.timer
sudo systemctl disable sr_mcureset.service
# replace the below services later
sudo systemctl disable sr_edge_nodes.service
sudo systemctl disable sr_edge_nodes_service_watcher.service
sudo systemctl disable sr_restreamer.service
