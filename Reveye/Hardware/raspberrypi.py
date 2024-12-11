def get_cpu_temp():

    with open("/sys/class/thermal/thermal_zone0/temp", "r") as file:
        temp = float(file.read()) / 1000
    return temp

# Usage
cpu_temp = get_cpu_temp()
print(f"CPU Temperature: {cpu_temp}°C")