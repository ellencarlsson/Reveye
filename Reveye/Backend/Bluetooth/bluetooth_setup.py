import dbus
import dbus.mainloop.glib
from gi.repository import GLib
from Bluetooth.gatt_server import Application, Service, Characteristic
import subprocess  # For enabling advertising

def enable_advertising():
    """Enable Bluetooth discoverability and advertising."""
    try:
        print("Enabling discoverable mode...")
        subprocess.run(["sudo", "bluetoothctl", "discoverable", "on"], check=True)

        print("Enabling advertising...")
        subprocess.run(["sudo", "bluetoothctl", "advertise", "on"], check=True)

        print("Bluetooth advertising enabled!")
    except subprocess.CalledProcessError as e:
        print(f"Error enabling Bluetooth advertising: {e}")

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
    """Reset the Bluetooth adapter to ensure it's ready for use."""
    try:
        print("Resetting Bluetooth adapter...")
        subprocess.run(["sudo", "hciconfig", "hci0", "down"], check=True)
        subprocess.run(["sudo", "hciconfig", "hci0", "up"], check=True)
        print("Bluetooth adapter reset successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error resetting Bluetooth adapter: {e}")

