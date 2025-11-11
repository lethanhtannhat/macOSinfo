#!/bin/zsh
export LC_ALL=C

# --- Collect and Process Data ---
HW=$(system_profiler SPHardwareDataType 2>/dev/null); DF=$(df -k / | tail -n 1)

# Basic Info
MODEL=$(echo "$HW" | awk -F': ' '/Model Name:/ {print $2}')
SERIAL=$(echo "$HW" | awk '/Serial Number \(system\):/ {print $4}')
CHIP=$(sysctl -n machdep.cpu.brand_string); RAM=$(echo "$HW" | awk '/Memory:/ {print $2, $3}')
USER_TYPE=$(id -Gn "$USER" | grep -q "admin" && echo "Admin" || echo "Standard")

# Storage Calculation (Base 10 GB)
read TOTAL_B USED_B AVAIL_B <<< $(echo "$DF" | awk '{print $2, $3, $4}') 
TOTAL_GB=$(echo "scale=2; $TOTAL_B * 1024 / 1000000000" | bc)
DF_AVAIL_GB=$(echo "scale=2; $AVAIL_B * 1024 / 1000000000" | bc)
# Status Checks
FV_STATUS=$(fdesetup status 2>/dev/null | head -n 1 | grep -q "On" && echo "FileVault is On" || echo "FileVault is Off")
AICLOUD_COUNT=$(defaults read MobileMeAccounts Accounts 2>/dev/null | grep 'AccountID' | wc -l)
if [ "$AICLOUD_COUNT" -gt 0 ]; then AID_STATUS="Signed In"; else AID_STATUS="Signed Out"; fi

# --- Build and Display Result ---
TEXT_OUTPUT=$(cat <<-EOF
Device Model:           $MODEL
Chip:                   $CHIP
Memory (RAM):           $RAM
Serial Number:          $SERIAL
Storage (Total GB):     ${TOTAL_GB} GB
FileVault Status:       $FV_STATUS
Current User:           $USER
User Type:              $USER_TYPE
Apple ID Status:        $AID_STATUS
EOF
)
osascript -e "display dialog \"$(echo "$TEXT_OUTPUT" | tr '\n' '\r')\" with title \"MACOS SYSTEM INFO\" buttons {\"OK\"} default button \"OK\""
