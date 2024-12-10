import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

# Custom UUIDs for your service and characteristic
SERVICE_UUID = '12345678-1234-1234-1234-123456789abc'
CHARACTERISTIC_UUID = '87654321-4321-4321-4321-cba987654321'

# Application to hold services
class Application(dbus.service.Object):
    def __init__(self, bus):
        self.path = '/org/bluez/example'
        self.services = []
        dbus.service.Object.__init__(self, bus, self.path)

    def add_service(self, service):
        self.services.append(service)

    def get_path(self):
        return self.path

    def get_services(self):
        return self.services


# Service to hold characteristics
class Service(dbus.service.Object):
    def __init__(self, bus, index, app):
        self.path = f"{app.path}/service{index}"
        self.uuid = SERVICE_UUID
        self.primary = True
        self.characteristics = []
        dbus.service.Object.__init__(self, bus, self.path)

    def add_characteristic(self, characteristic):
        self.characteristics.append(characteristic)

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        if interface == "org.bluez.GattService1":
            return {
                "UUID": self.uuid,
                "Primary": self.primary,
            }
        return {}

    @dbus.service.method("org.freedesktop.DBus.Introspectable", in_signature="", out_signature="s")
    def Introspect(self):
        return f"""
        <node>
            <interface name='org.bluez.GattService1'>
                <property name='UUID' type='s' access='read'/>
                <property name='Primary' type='b' access='read'/>
            </interface>
        </node>
        """


# Writable characteristic to handle commands
class Characteristic(dbus.service.Object):
    def __init__(self, bus, index, service):
        self.path = f"{service.path}/char{index}"
        self.uuid = CHARACTERISTIC_UUID
        self.flags = ["write"]
        self.value = b""
        dbus.service.Object.__init__(self, bus, self.path)

    @dbus.service.method("org.freedesktop.DBus.Properties", in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        if interface == "org.bluez.GattCharacteristic1":
            return {
                "UUID": self.uuid,
                "Service": self.service.get_path(),
                "Flags": self.flags,
            }
        return {}

    @dbus.service.method("org.bluez.GattCharacteristic1", in_signature="aya{sv}", out_signature="")
    def WriteValue(self, value, options):
        self.value = bytes(value)
        command = self.value.decode("utf-8")
        print(f"Received command: {command}")

        if command == "start":
            print("Starting process on Raspberry Pi...")
            # Add your logic for "start" command here
        elif command == "stop":
            print("Stopping process on Raspberry Pi...")
            # Add your logic for "stop" command here
        else:
            print(f"Unknown command: {command}")


