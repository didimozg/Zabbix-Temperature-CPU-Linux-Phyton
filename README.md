# 🌡️ Zabbix Advanced CPU Temperature (Python/Sysfs)

![Zabbix 7.0+](https://img.shields.io/badge/Zabbix-7.0%2B-blue) ![Python 3](https://img.shields.io/badge/Python-3.x-yellow) ![Method Sysfs](https://img.shields.io/badge/Method-Direct_Sysfs-green) ![License](https://img.shields.io/badge/License-MIT-grey)

An advanced solution for monitoring CPU temperatures in Zabbix.

Unlike standard solutions, this method **does not** parse the output of the `sensors` (lm-sensors) command. Instead, it uses a Python script to directly read values from the Linux kernel interface (`/sys/class/hwmon`). This ensures high performance, zero shell overhead, and independence from utility version changes.

### 🚀 Features
* **Auto-Discovery (LLD):** Automatically detects all CPU cores and physical packages.
* **Smart Detection:** Automatically identifies the correct driver (`coretemp` for Intel, `k10temp`/`zenpower` for AMD).
* **Metrics:** Per-core temperature + Aggregated data (Min / Max / Avg across all cores).
* **Graphs:** Automatic graph creation for every core and a summary graph.
* **Zabbix 7.4 Ready:** Fully compatible with newer Zabbix versions (UUIDv4 compliant).

---

## 🧠 Trigger Logic (Best Practices)

This template uses a **"Funnel Strategy"** for triggers. This filters out short-term temperature spikes (e.g., Turbo Boost, compilation, backups) and alerts only on actual cooling system failures.

| Temperature | Delay | Severity | Problem Description |
| :--- | :--- | :--- | :--- |
| **> 70°C** | 30 min | `Info` | Chronic high load. Not critical, but worth noting. |
| **> 80°C** | 10 min | `Warning` | Cooling inefficiency. Temperature remains high for too long. |
| **> 90°C** | 3 min | `Average` | **Overheating.** Cooling system cannot dissipate heat. Risk of throttling. |
| **> 95°C** | 1 min | `High` | Critical zone. Close to T-Junction max. |
| **> 100°C** | Instant | `Disaster` | Emergency. Risk of hardware shutdown/damage. |

---

## 🛠️ Quick Install (One-Click)

You can install the script and configure the agent automatically with a single command:

```bash
curl -s https://raw.githubusercontent.com/didimozg/Zabbix-Temperature-CPU-Linux-Phyton/refs/heads/main/install.sh | sudo bash

```
## 🛠️ Manual Installation:
### 1. Python Script
The script handles core discovery and Sysfs reading.

1. Create a directory for external scripts (if it doesn't exist):
   ```bash
   sudo mkdir -p /etc/zabbix/scripts


2. Copy the `zbx_py_cputemp.py` file from this repository to `/etc/zabbix/scripts/`.
3. Make the script executable:
```bash
sudo chmod +x /etc/zabbix/scripts/zbx_py_cputemp.py

```



### 2. Zabbix Agent Configuration

We only need to add a single `UserParameter`. The logic is handled inside the Python script.

1. Create a config file `/etc/zabbix/zabbix_agent2.d/python_cputemp.conf`:
```ini
UserParameter=py.cputemp[*],/etc/zabbix/scripts/zbx_py_cputemp.py $1 $2

```


2. Restart the agent:
```bash
# For Zabbix Agent 2
sudo systemctl restart zabbix-agent2

# Or for the standard agent
sudo systemctl restart zabbix-agent

```



### 3. Import Template

1. Download `template_cputemp.yaml`.
2. Open Zabbix Web UI: **Data collection** → **Templates** → **Import**.
3. Upload the file and link the template to your target host.

---

## ❓ Troubleshooting

You can test the script directly from the server console:

```bash
# 1. Test Discovery (should return JSON)
zabbix_agent2 -t py.cputemp[discovery]

# 2. Test fetching Average Temperature
zabbix_agent2 -t py.cputemp[avg]

```

*Note: If you encounter permission errors, ensure the `zabbix` user has read access to `/sys/class/hwmon/*` (usually enabled by default on most distros).*

---

## File Structure

* `zbx_py_cputemp.py` — Main collector script.
* `template_cputemp.yaml` — Zabbix Template (Triggers, Items, Graphs).
* `README.md` — Documentation.
