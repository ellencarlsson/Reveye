import os
import subprocess

def get_cpu_temp():

    with open("/sys/class/thermal/thermal_zone0/temp", "r") as file:
        temp = float(file.read()) / 1000
    return temp

def set_wifi(name, password):
    """
    Set the Wi-Fi network on the Raspberry Pi.

    :param name: SSID of the Wi-Fi network.
    :param password: Password for the Wi-Fi network.
    """
    # Define the Wi-Fi configuration file path
    config_path = "/etc/wpa_supplicant/wpa_supplicant.conf"
    
    # Wi-Fi configuration content
    wifi_config = f"""
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={{
    ssid="{name}"
    psk="{password}"
}}
"""
    try:
        # Write Wi-Fi configuration to file
        with open(config_path, 'w') as config_file:
            config_file.write(wifi_config)
        
        # Ensure proper permissions
        os.chmod(config_path, 0o600)
        
        # Reconfigure the Wi-Fi
        subprocess.run(["sudo", "wpa_cli", "-i", "wlan0", "reconfigure"], check=True)

        print(f"Wi-Fi set to SSID: {name}. Reconnecting...")
    except Exception as e:
        print(f"Failed to set Wi-Fi: {e}")

def get_connected_wifi():
    """
    Get the SSID of the Wi-Fi network the Raspberry Pi is connected to.

    :return: The SSID of the connected Wi-Fi network, or None if not connected.
    """
    try:
        # Run the iwgetid command to get the current Wi-Fi SSID
        result = subprocess.run(
            ["iwgetid", "-r"],
            capture_output=True,
            text=True,
            check=True
        )
        # Return the SSID (strip whitespace and newline)
        ssid = result.stdout.strip()
        if ssid:
            print(f"SSID: {ssid}")
            return ssid
        else:
            print("Found no SSID")
            return None
    except subprocess.CalledProcessError:
        return None
