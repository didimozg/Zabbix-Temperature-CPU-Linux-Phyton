#!/bin/bash
# 🛠️ Installer for Zabbix CPU Temp (Python/Sysfs)
# Repo: https://github.com/didimozg/Zabbix-Temperature-CPU-Linux-Phyton

# === Settings ===
SCRIPT_URL="https://raw.githubusercontent.com/didimozg/Zabbix-Temperature-CPU-Linux-Phyton/refs/heads/main/zbx_py_cputemp.py"
SCRIPT_DIR="/etc/zabbix/scripts"
SCRIPT_PATH="$SCRIPT_DIR/zbx_py_cputemp.py"
# Agent 2 default
CONFIG_FILE="/etc/zabbix/zabbix_agent2.d/python_cputemp.conf"
# Agent 1 default
CONFIG_FILE_OLD="/etc/zabbix/zabbix_agentd.d/python_cputemp.conf"

# === Checks ===
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run as root (use sudo)."
  exit 1
fi

echo "🚀 Starting installation..."

# 1. Create Directory
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "📂 Creating directory $SCRIPT_DIR..."
    mkdir -p "$SCRIPT_DIR"
fi

# 2. Download Script
echo "⬇️ Downloading Python script..."
if command -v curl >/dev/null 2>&1; then
    curl -s -o "$SCRIPT_PATH" "$SCRIPT_URL"
elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$SCRIPT_PATH" "$SCRIPT_URL"
else
    echo "❌ Error: curl or wget not found."
    exit 1
fi

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Error: Download failed."
    exit 1
fi

chmod +x "$SCRIPT_PATH"
echo "✅ Script downloaded and executable set."

# 3. Create Zabbix Config
TARGET_CONF="$CONFIG_FILE"
if [ ! -d "/etc/zabbix/zabbix_agent2.d" ] && [ -d "/etc/zabbix/zabbix_agentd.d" ]; then
    TARGET_CONF="$CONFIG_FILE_OLD"
fi

echo "⚙️ Creating config: $TARGET_CONF"
echo "UserParameter=py.cputemp[*],$SCRIPT_PATH \$1 \$2" > "$TARGET_CONF"

# 4. Restart Agent
echo "🔄 Restarting Zabbix Agent..."
if systemctl list-units --full -all | grep -q "zabbix-agent2.service"; then
    systemctl restart zabbix-agent2
    echo "✅ Zabbix Agent 2 restarted."
elif systemctl list-units --full -all | grep -q "zabbix-agent.service"; then
    systemctl restart zabbix-agent
    echo "✅ Zabbix Agent restarted."
else
    echo "⚠️ Warning: Could not detect running Zabbix Agent service. Please restart it manually."
fi

echo "-------------------------------------------------------"
echo "🎉 Installation Complete!"
echo "Now import the Template YAML file into Zabbix Server."
echo "-------------------------------------------------------"
