import sys
sys.path.append('.')
import dbus, dbus.mainloop.glib
from gi.repository import GLib


from Reveye.Backend.example_advertisement import Advertisement
from Reveye.Backend.example_advertisement import register_ad_cb, register_ad_error_cb
from example_gatt_server import Service, Characteristic
from example_gatt_server import register_app_cb, register_app_error_cb

BLUEZ_SERVICE_NAME = 'org.bluez'
DBUS_OM_IFACE = 'org.freedesktop.DBus.ObjectManager'
LE_ADVERTISING_MANAGER_IFACE = 'org.bluez.LEAdvertisingManager1'
GATT_MANAGER_IFACE = 'org.bluez.GattManager1'
GATT_CHRC_IFACE = 'org.bluez.GattCharacteristic1'
UART_SERVICE_UUID = '6e400001-b5a3-f393-00a9-e50e24dcca9e'
UART_TX_CHARACTERISTIC_UUID = '6e400003-b5a3-f393-00a9-e50e24dcca9e'
UART_SE_CHARACTERISTIC_UUID = '6e400006-b5a3-f393-00a9-e50e24dcca9e'
mainloop = None


class DemoCharacteristic(Characteristic):

    def __init__(self, bus, index, service):
        Characteristic.__init__(self, bus, index, UART_TX_CHARACTERISTIC_UUID,
                                ['read', 'write', 'notify'], service)
        self.logger = ai.coloredlogging.get_logger("Play",
                                                   ai.coloredlogging.WHITE)
        self.logger.addHandler(logging.NullHandler())

        self.notifying = False
        #GLib.io_add_watch(sys.stdin, GLib.IO_IN, self.notify_voic_command)

    def WriteValue(self, value, options):
        """
        Let client to write data to here.
        Receive notify type data to change the notify type.
        Receive command to enable and disable the control mode.
        Receive action command to control MarsCat.
        """
        s = bytes(value).decode()
        print(s)

    def ReadValue(self, options):
        """
        Let client to read data from here.
        """
        return [dbus.Byte(1)]

    def StartNotify(self):
        if self.notifying:
            self.logger.debug('Already notifying, nothing to do')
            return

        self.notifying = True
        self.toggle_notification()
        print('start notify')

    def StopNotify(self):
        if not self.notifying:
            self.logger.debug('Not notifying, nothing to do')
            return

        self.notifying = False
        self.toggle_notification()
        print('stop notify')

    def notify_any(self):
        if not self.notifying:
            return

        send_dict = {}

        send_dict['voice'] = 'hello'
        send_dict['vision'] = 'face'
        send_dict['touch'] = 'head'
        send_dict['distance'] = '199'
        send_dict['gyro'] = '0-0'

        data = json.dumps(send_dict)
        print('data : [{}]'.format(data))
        value = []
        for b in data:
            value.append(dbus.Byte(b.encode()))

        self.PropertiesChanged(GATT_CHRC_IFACE, {'Value': value}, [])

    def do_notify(self):
        """
        According the receive command to change the notify data.
        """

        self.notify_any()
        return True

    def toggle_notification(self):
        if not self.notifying:
            return

        # each 1s notify one time.
        GObject.timeout_add(1000, self.do_notify)


class TestCharacteristic(Characteristic):
    def __init__(self, bus, index, service):
        Characteristic.__init__(self, bus, index, UART_SE_CHARACTERISTIC_UUID,
                                ['read'], service)
        self.logger = ai.coloredlogging.get_logger("State",
                                                   ai.coloredlogging.RED)
        self.logger.addHandler(logging.NullHandler())

    def ReadValue(self, options):
        v = 'abcdefg'
        value = []
        for b in v:
            value.append(dbus.Byte(b.encode()))
        return value


class UartService(Service):
    def __init__(self, bus, index):
        Service.__init__(self, bus, index, UART_SERVICE_UUID, True)
        self.add_characteristic(DemoCharacteristic(bus, 0, self))
        self.add_characteristic(TestCharacteristic(bus, 1, self))


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
        self.add_local_name(ai.parameters.CAT_BLE_NAME)
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
    adapter = find_adapter(bus)
    if not adapter:
        print('BLE adapter not found')
        return

    service_manager = dbus.Interface(
        bus.get_object(BLUEZ_SERVICE_NAME, adapter), GATT_MANAGER_IFACE)
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