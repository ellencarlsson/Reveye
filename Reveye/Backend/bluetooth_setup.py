import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import subprocess  # Import subprocess to run system commands

class Application(dbus.service.Object):
    def __init__(self, bus):
        self.path = '/org/bluez/example'
        self.bus = bus
        self.bus_name = dbus.service.BusName("org.bluez", bus=bus)
        dbus.service.Object.__init__(self, self.bus_name, self.path)

class Service(dbus.service.Object):
    UUID = '12345678-1234-5678-1234-56789abcdef0'  # Custom Service UUID
    def __init__(self, bus, index, app):
        self.path = f'{app.path}/service{index}'
        self.bus = bus
        dbus.service.Object.__init__(self, self.bus, self.path)

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature='', out_signature='a{sv}')
    def GetAll(self):
        return {'UUID': self.UUID, 'Primary': True}

class Characteristic(dbus.service.Object):
    UUID = '12345678-1234-5678-1234-56789abcdef1'  # Custom Characteristic UUID
    def __init__(self, bus, index, service):
        self.path = f'{service.path}/char{index}'
        self.bus = bus
        dbus.service.Object.__init__(self, self.bus, self.path)
        self.value = b"Hello, iPhone!"  # Default Value

    @dbus.service.method("org.bluez.GattCharacteristic1", in_signature='a{sv}', out_signature='ay')
    def ReadValue(self, options):
        print(f"ReadValue called: {self.value}")
        return dbus.Array(self.value, signature='y')

    @dbus.service.method("org.bluez.GattCharacteristic1", in_signature='aya{sv}', out_signature='')
    def WriteValue(self, value, options):
        self.value = bytes(value)
        print(f"WriteValue called: {self.value.decode('utf-8')}")

def enable_advertising():
    """Enable BLE advertising and discoverability."""
    bus = dbus.SystemBus()
    adapter_path = "/org/bluez/hci0"

    # Get the adapter object
    adapter = dbus.Interface(bus.get_object("org.bluez", adapter_path), "org.freedesktop.DBus.Properties")

    adapter.Set("org.bluez.Adapter1", "Alias", "Reveye")

    # Enable discoverable and advertising
    print("Enabling discoverable and advertising...")
    adapter.Set("org.bluez.Adapter1", "Powered", dbus.Boolean(True))
    adapter.Set("org.bluez.Adapter1", "Discoverable", dbus.Boolean(True))

    # Enable LE advertising using subprocess
    try:
        subprocess.run(["sudo", "hciconfig", "hci0", "leadv", "0"], check=True)
        print("BLE advertising enabled!")
    except subprocess.CalledProcessError as e:
        print(f"Failed to enable BLE advertising: {e}")

def main():
    print("Initializing D-Bus...")
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    print("Creating GATT application...")
    app = Application(bus)

    # Add GATT services
    service = Service(bus, 0, app)
    characteristic = Characteristic(bus, 0, service)

    # Enable BLE advertising
    enable_advertising()

    print("Starting main event loop...")
    mainloop = GLib.MainLoop()
    mainloop.run()

if __name__ == '__main__':
    print("Starting GATT server...")
    main()
