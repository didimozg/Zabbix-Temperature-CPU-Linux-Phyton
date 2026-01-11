#!/usr/bin/env python3
import os
import json
import sys
import glob

# Base path to hardware monitoring sensors in Linux
HWMON_PATH = "/sys/class/hwmon"

def get_cpu_hwmon_dir():
    """Finds the hwmon directory responsible for CPU (coretemp or k10temp)."""
    for hwmon in glob.glob(os.path.join(HWMON_PATH, 'hwmon*')):
        try:
            with open(os.path.join(hwmon, 'name'), 'r') as f:
                name = f.read().strip()
                # Support for Intel and AMD
                if name in ['coretemp', 'k10temp', 'zenpower']:
                    return hwmon
        except Exception:
            continue
    return None

def discovery():
    """Generates LLD JSON for Zabbix."""
    hwmon_dir = get_cpu_hwmon_dir()
    data = []
    
    if not hwmon_dir:
        print(json.dumps({"data": []}))
        return

    # Look for temp*_input files
    for sensor_path in glob.glob(os.path.join(hwmon_dir, 'temp*_input')):
        try:
            # Get the label name (e.g., Core 0) if the _label file exists
            label_path = sensor_path.replace('_input', '_label')
            if os.path.exists(label_path):
                with open(label_path, 'r') as f:
                    label = f.read().strip()
            else:
                # If no label exists, use the filename (relevant for AMD Package)
                label = os.path.basename(sensor_path)

            data.append({
                "{#SENSOR_LABEL}": label,
                "{#SENSOR_PATH}": sensor_path
            })
        except Exception:
            pass
            
    print(json.dumps({"data": data}))

def get_value(path):
    """Reads the value from a file and converts it to degrees Celsius."""
    try:
        with open(path, 'r') as f:
            # Value in the file is in millidegrees (45000 = 45C)
            val = int(f.read().strip())
            print(f"{val / 1000:.1f}")
    except Exception:
        print("-1")

def get_stat(stat_type):
    """Calculates min/max/avg across all found cores."""
    hwmon_dir = get_cpu_hwmon_dir()
    values = []
    if hwmon_dir:
        for sensor_path in glob.glob(os.path.join(hwmon_dir, 'temp*_input')):
             try:
                with open(sensor_path, 'r') as f:
                    values.append(int(f.read().strip()) / 1000)
             except: pass
    
    if not values:
        print("-1")
        return

    if stat_type == 'avg':
        print(f"{sum(values) / len(values):.1f}")
    elif stat_type == 'max':
        print(f"{max(values):.1f}")
    elif stat_type == 'min':
        print(f"{min(values):.1f}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    
    mode = sys.argv[1]
    
    if mode == 'discovery':
        discovery()
    elif mode == 'value' and len(sys.argv) == 3:
        get_value(sys.argv[2])
    elif mode in ['avg', 'min', 'max']:
        get_stat(mode)
