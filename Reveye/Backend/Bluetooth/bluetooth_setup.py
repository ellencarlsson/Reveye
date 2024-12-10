import dbus
import dbus.mainloop.glib
import dbus.service
from gi.repository import GLib
import subprocess
from Bluetooth.gatt_server import Application, Service, Characteristic

class PairingAgent(dbus.service.Object):
    """Handles pairing requests and provides a PIN or passkey for pairing."""

    AGENT_PATH = "/test/agent"

    def __init__(self, bus):
        super().__init__(bus, self.AGENT_PATH)

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="u")
    def RequestPasskey(self, device):
        print(f"Passkey request from device: {device}")
        passkey = 123456  # Use a six-digit passkey
        print(f"Providing passkey: {passkey}")
        return dbus.UInt32(passkey)

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="s")
    def RequestPinCode(self, device):
        print(f"Pin code request from device: {device}")
        pin_code = "1234"  # Static PIN code (less commonly used now)
        print(f"Providing PIN code: {pin_code}")
        return pin_code

    @dbus.service.method("org.bluez.Agent1", in_signature="os", out_signature="")
    def DisplayPasskey(self, device, passkey):
        print(f"Displaying passkey {passkey} for device {device}")

    @dbus.service.method("org.bluez.Agent1", in_signature="ou", out_signature="")
    def RequestConfirmation(self, device, passkey):
        print(f"Confirming passkey {passkey} for device {device}")
        # Auto-confirm the passkey
        return


    @dbus.service.method("org.bluez.Agent1", in_signature="", out_signature="")
    def Release(self):
        print("Agent released")

    @dbus.service.method("org.bluez.Agent1", in_signature="", out_signature="")
    def Cancel(self):
        print("Pairing canceled")



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


def register_agent(bus):
    """Register the pairing agent with BlueZ."""
    agent_manager = dbus.Interface(
        bus.get_object("org.bluez", "/org/bluez"),
        "org.bluez.AgentManager1"
    )

    agent = PairingAgent(bus)
    print("Registering pairing agent...")
    agent_manager.RegisterAgent(agent.AGENT_PATH, "DisplayYesNo")
    agent_manager.RequestDefaultAgent(agent.AGENT_PATH)
    print("Pairing agent registered and set as default.")



def start_bluetooth():
    print("Initializing D-Bus...")
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()

    # Register the pairing agent
    register_agent(bus)

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
