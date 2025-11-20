from gi.repository import GLib as glib
from pyudev import Context, Monitor, MonitorObserver
import subprocess

dfm_mount_dir="/srv/sr/dfmusb"

def device_event(device):
    print('event {0} on device {1}'.format(device.action, device))
    print('event {0} on device {1}'.format(device.sys_name, device))
    print('Device name: %s' % device.get('DEVNAME'))
    if device.action == "add":
        print("add")
        subprocess.call('echo {} | sudo -S {} {} {}'.format("sahana123", "mount", device.get('DEVNAME'),dfm_mount_dir), shell=True)

def initialize():
	context = Context()
	monitor = Monitor.from_netlink(context)
	monitor.filter_by(subsystem='block')
	observer = MonitorObserver(monitor, callback=device_event, name = 'monitor-observer')
	observer.daemon
	observer.start()

initialize()

glib.MainLoop().run()
