import bluetooth

class BluetoothServer:
    def __init__(self):
        self.server_sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)

    def setup(self):
        self.server_sock.bind(("", bluetooth.PORT_ANY))
        self.server_sock.listen(1)
        port = self.server_sock.getsockname()[1]
        bluetooth.advertise_service(
            self.server_sock,
            "ReveyeServer",
            service_classes=[bluetooth.SERIAL_PORT_CLASS],
            profiles=[bluetooth.SERIAL_PORT_PROFILE],
        )
        print(f"Bluetooth server is set up and listening on port {port}...")

    def wait_for_connection(self):
        print("Waiting for a connection...")
        client_sock, client_info = self.server_sock.accept()
        print(f"Accepted connection from {client_info}")
        return client_sock

    def close(self):
        self.server_sock.close()

# If needed, expose specific functions or constants
def initialize_bluetooth():
    print("Initializing Bluetooth...")
