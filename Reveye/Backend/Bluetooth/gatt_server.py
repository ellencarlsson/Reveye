import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import dbus
import dbus.service
from gi.repository import GLib

# Custom UUID for your service and characteristic
SERVICE_UUID = '12345678-1234-1234-1234-123456789abc'
CHARACTERISTIC_UUID = '87654321-4321-4321-4321-cba987654321'

# This will represent the GATT service that will handle the commands
class Application(dbus.service.Object):
    def __init__(self, bus):
        self.path = '/org/bluez/example'
        self.bus = bus
        self.bus_name = dbus.service.BusName("org.bluez", bus=bus)
        dbus.service.Object.__init__(self, self.bus_name, self.path)

# Service class for your custom service
class Service(dbus.service.Object):
    def __init__(self, bus, index, app):
        self.path = f'{app.path}/service{index}'
        self.bus = bus
        dbus.service.Object.__init__(self, self.bus, self.path)

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature='', out_signature='a{sv}')
    def GetAll(self):
        return {'UUID': SERVICE_UUID, 'Primary': True}

# Characteristic class to handle commands sent to the Raspberry Pi
class Characteristic(dbus.service.Object):
    def __init__(self, bus, index, service):
        self.path = f'{service.path}/char{index}'
        self.bus = bus
        dbus.service.Object.__init__(self, self.bus, self.path)
        self.value = b""  # Initialize with an empty value
        self.uuid = CHARACTERISTIC_UUID  # Set the UUID for the writable characteristic

    @dbus.service.method("org.bluez.GattCharacteristic1", in_signature='aya{sv}', out_signature='')
    def WriteValue(self, value, options):
        self.value = bytes(value)
        command = self.value.decode('utf-8')
        print(f"Received command: {command}")
        
        if command == "start":
            print("Starting process on Raspberry Pi...")
            # Trigger an action on Raspberry Pi
        elif command == "stop":
            print("Stopping process on Raspberry Pi...")
            # Trigger a stop action on Raspberry Pi
        else:
            print(f"Unknown command: {command}")

# Set up Bluez and start the service
def start_bluetooth():
    print("Initializing D-Bus...")
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()

    print("Creating GATT application...")
    app = Application(bus)
    service = Service(bus, 0, app)
    characteristic = Characteristic(bus, 0, service)

    print("Starting main event loop...")
    mainloop = GLib.MainLoop()
    mainloop.run()
