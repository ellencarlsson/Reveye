import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

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
        self.value = b""  # Initialize with an empty value

    @dbus.service.method("org.bluez.GattCharacteristic1", in_signature='a{sv}', out_signature='ay')
    def ReadValue(self, options):
        print(f"ReadValue called: {self.value}")
        return dbus.Array(self.value, signature='y')

    @dbus.service.method("org.bluez.GattCharacteristic1", in_signature='aya{sv}', out_signature='')
    def WriteValue(self, value, options):
        self.value = bytes(value)
        command = self.value.decode('utf-8')
        print(f"WriteValue called: {command}")

        # Handle commands like 'start' or 'stop'
        if command == "start":
            print("Command received: START")
        elif command == "stop":
            print("Command received: STOP")
        else:
            print(f"Unknown command: {command}")
