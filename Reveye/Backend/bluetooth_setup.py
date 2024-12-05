import subprocess

def setup_bluetooth():
    try:
        # Enable Bluetooth power
        subprocess.run(["bluetoothctl", "power", "on"], check=True)

        # Make the device discoverable
        subprocess.run(["bluetoothctl", "discoverable", "on"], check=True)

        # Set the Bluetooth device's name (for BLE advertisement)
        subprocess.run(["bluetoothctl", "system-alias", "Reveye Device"], check=True)

       
        print("Bluetooth is now powered on, discoverable, and advertising.")
        

    except subprocess.CalledProcessError as e:
        print(f"Error setting up Bluetooth: {e}")

