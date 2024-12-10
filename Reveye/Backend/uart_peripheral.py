import sys
import dbus, dbus.mainloop.glib
from gi.repository import GLib
from advertisement import Advertisement
from advertisement import register_ad_cb, register_ad_error_cb
from gatt_server import Service, Characteristic
from gatt_server import register_app_cb, register_app_error_cb
from time import time

BLUEZ_SERVICE_NAME =           'org.bluez'
DBUS_OM_IFACE =                'org.freedesktop.DBus.ObjectManager'
LE_ADVERTISING_MANAGER_IFACE = 'org.bluez.LEAdvertisingManager1'
GATT_MANAGER_IFACE =           'org.bluez.GattManager1'
GATT_CHRC_IFACE =              'org.bluez.GattCharacteristic1'
UART_SERVICE_UUID =            '6e400001-b5a3-f393-e0a9-e50e24dcca9e'
UART_RX_CHARACTERISTIC_UUID =  '6e400002-b5a3-f393-e0a9-e50e24dcca9e'
UART_TX_CHARACTERISTIC_UUID =  '6e400003-b5a3-f393-e0a9-e50e24dcca9e'
LOCAL_NAME =                   'rpi-gatt-server'
mainloop = None

class PairingAgent(dbus.service.Object):
    AGENT_PATH = "/test/agent"

    def __init__(self, bus):
        super().__init__(bus, self.AGENT_PATH)

    # Provide passkey for pairing
    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="u")
    def RequestPasskey(self, device):
        passkey = 123456  # The passkey you want to use for pairing
        print(f"Passkey requested for device: {device}, providing passkey: {passkey}")
        return dbus.UInt32(passkey)

    # Display passkey for the user
    @dbus.service.method("org.bluez.Agent1", in_signature="os", out_signature="")
    def DisplayPasskey(self, device, passkey):
        print(f"Displaying passkey {passkey} for device {device}")

    # Confirm passkey automatically
    @dbus.service.method("org.bluez.Agent1", in_signature="ou", out_signature="")
    def RequestConfirmation(self, device, passkey):
        print(f"Confirming passkey {passkey} for device {device}")
        return  # Automatically confirm

    # Cancel pairing
    @dbus.service.method("org.bluez.Agent1", in_signature="", out_signature="")
    def Cancel(self):
        print("Pairing canceled")

def register_agent(bus):
    agent_manager = dbus.Interface(bus.get_object("org.bluez", "/org/bluez"), "org.bluez.AgentManager1")
    agent = PairingAgent(bus)
    agent_manager.RegisterAgent(agent.AGENT_PATH, "DisplayYesNo")
    agent_manager.RequestDefaultAgent(agent.AGENT_PATH)
    print("Pairing agent registered and set as default.")

class TxCharacteristic(Characteristic):
    def __init__(self, bus, index, service):
        Characteristic.__init__(self, bus, index, UART_TX_CHARACTERISTIC_UUID,
                                ['notify'], service)
        self.notifying = False
        GLib.io_add_watch(sys.stdin, GLib.IO_IN, self.on_console_input)
        self.last_notify_time = time()
        GLib.timeout_add(15000, self.notify_timer)

    def notify_timer(self):
        # This method will be called every 30 seconds
        if time() - self.last_notify_time >= 15:  # Check if 30 seconds have passed
            self.send_tx("Tass och udo")  # Send notification text
            self.last_notify_time = time()  # Reset the timer

        return True

    def on_console_input(self, fd, condition):
        s = fd.readline()
        if s.isspace():
            pass
        else:
            self.send_tx(s)
        return True

    def send_tx(self, s):
        if not self.notifying:
            return
        
        # Create a list to hold individual bytes for each character
        value = []

        # Send the dynamic message from the input string `s`
        for c in s:
            value.append(dbus.Byte(c.encode()))  # Send each byte of input string
        
        # Notify the iPhone app (or any connected device) via the TX characteristic
        self.PropertiesChanged(GATT_CHRC_IFACE, {'Value': value}, [])
        print(f"Sent notification: {s}")


    def StartNotify(self):
        if self.notifying:
            return
        self.notifying = True

    def StopNotify(self):
        if not self.notifying:
            return
        self.notifying = False

class RxCharacteristic(Characteristic):
    def __init__(self, bus, index, service):
        Characteristic.__init__(self, bus, index, UART_RX_CHARACTERISTIC_UUID,
                                ['write'], service)

    def WriteValue(self, value, options):
        print('command: {}'.format(bytearray(value).decode()))

class UartService(Service):
    def __init__(self, bus, index):
        Service.__init__(self, bus, index, UART_SERVICE_UUID, True)
        self.add_characteristic(TxCharacteristic(bus, 0, self))
        self.add_characteristic(RxCharacteristic(bus, 1, self))

class Application(dbus.service.Object):
    def __init__(self, bus):
        self.path = '/'
        self.services = []
        dbus.service.Object.__init__(self, bus, self.path)

    def get_path(self):
        return dbus.ObjectPath(self.path)

    def add_service(self, service):
        self.services.append(service)

    @dbus.service.method(DBUS_OM_IFACE, out_signature='a{oa{sa{sv}}}')
    def GetManagedObjects(self):
        response = {}
        for service in self.services:
            response[service.get_path()] = service.get_properties()
            chrcs = service.get_characteristics()
            for chrc in chrcs:
                response[chrc.get_path()] = chrc.get_properties()
        return response

class UartApplication(Application):
    def __init__(self, bus):
        Application.__init__(self, bus)
        self.add_service(UartService(bus, 0))

class UartAdvertisement(Advertisement):
    def __init__(self, bus, index):
        Advertisement.__init__(self, bus, index, 'peripheral')
        self.add_service_uuid(UART_SERVICE_UUID)
        self.add_local_name(LOCAL_NAME)
        self.include_tx_power = True

def find_adapter(bus):
    remote_om = dbus.Interface(bus.get_object(BLUEZ_SERVICE_NAME, '/'),
                               DBUS_OM_IFACE)
    objects = remote_om.GetManagedObjects()
    for o, props in objects.items():
        if LE_ADVERTISING_MANAGER_IFACE in props and GATT_MANAGER_IFACE in props:
            return o
        print('Skip adapter:', o)
    return None

def main():
    global mainloop
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    
    bus = dbus.SystemBus()
    register_agent(bus)

    adapter = find_adapter(bus)
    if not adapter:
        print('BLE adapter not found')
        return

    service_manager = dbus.Interface(
                                bus.get_object(BLUEZ_SERVICE_NAME, adapter),
                                GATT_MANAGER_IFACE)
    ad_manager = dbus.Interface(bus.get_object(BLUEZ_SERVICE_NAME, adapter),
                                LE_ADVERTISING_MANAGER_IFACE)

    app = UartApplication(bus)
    adv = UartAdvertisement(bus, 0)

    mainloop = GLib.MainLoop()

    service_manager.RegisterApplication(app.get_path(), {},
                                        reply_handler=register_app_cb,
                                        error_handler=register_app_error_cb)
    ad_manager.RegisterAdvertisement(adv.get_path(), {},
                                     reply_handler=register_ad_cb,
                                     error_handler=register_ad_error_cb)
    try:
        mainloop.run()
    except KeyboardInterrupt:
        adv.Release()

if __name__ == '__main__':
    main()

