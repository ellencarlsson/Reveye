import dbus
import dbus.mainloop.glib
from gi.repository import GLib
from Bluetooth.gatt_server import Application, Service, Characteristic
import subprocess  # For enabling advertising

def enable_advertising():
    """Enable BLE advertising and discoverability."""
    bus = dbus.SystemBus()
    adapter_path = "/org/bluez/hci0"

    # Get the adapter object
    adapter = dbus.Interface(bus.get_object("org.bluez", adapter_path), "org.freedesktop.DBus.Properties")

    # Set the full local name explicitly
    print("Setting alias to 'Reveye Device'...")
    adapter.Set("org.bluez.Adapter1", "Alias", "Reveye Device")

    # Enable discoverable and advertising
    print("Enabling discoverable and advertising...")
    adapter.Set("org.bluez.Adapter1", "Powered", dbus.Boolean(True))
    adapter.Set("org.bluez.Adapter1", "Discoverable", dbus.Boolean(True))

    # Enable LE advertising
    try:
        subprocess.run(["sudo", "hciconfig", "hci0", "leadv", "0"], check=True)
        print("BLE advertising enabled!")
    except subprocess.CalledProcessError as e:
        print(f"Failed to enable BLE advertising: {e}")

def start_bluetooth():
    print("Initializing D-Bus...")
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    print("Creating GATT application...")
    app = Application(bus)

    # Reset Bluetooth adapter before enabling advertising
    reset_bluetooth_adapter()

    # Add GATT services
    service = Service(bus, 0, app)
    characteristic = Characteristic(bus, 0, service)

    # Enable BLE advertising
    enable_advertising()

    print("Starting main event loop...")
    mainloop = GLib.MainLoop()
    mainloop.run()


    

def reset_bluetooth_adapter():
    try:
        print("Resetting Bluetooth adapter...")
        subprocess.run(["sudo", "hciconfig", "hci0", "down"], check=True)
        subprocess.run(["sudo", "hciconfig", "hci0", "up"], check=True)
        print("Bluetooth adapter reset successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error resetting Bluetooth adapter: {e}")

