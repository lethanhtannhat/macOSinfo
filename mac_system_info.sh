#!/bin/zsh

# Set locale to C to ensure consistent output for commands.
export LC_ALL=C

# --- macOS System Information Collector ---

echo "\n=============================================="
echo "        MACOS SYSTEM INFORMATION"
echo "=============================================="

# 1. Hardware, Chip, and Memory Info
HARDWARE_INFO=$(system_profiler SPHardwareDataType 2>/dev/null)
DEVICE_MODEL=$(echo "$HARDWARE_INFO" | grep 'Model Name:' | awk -F': ' '{print $2}')
SERIAL_NUMBER=$(echo "$HARDWARE_INFO" | grep "Serial Number (system):" | awk '{print $4}')
CHIP_INFO=$(sysctl -n machdep.cpu.brand_string)
MEMORY_INFO=$(echo "$HARDWARE_INFO" | awk '/Memory:/ {print $2, $3}')


# --- DISK CAPACITY CALCULATION FUNCTION (using df and bc) ---
get_storage_details() {
    # Get disk capacity info for root (/) in 1K-blocks (1024 bytes)
    local DF_DATA=$(df -k / | tail -n 1)

    # 1. Extract Total Blocks (Column 2 from df -k)
    local TOTAL_BLOCKS=$(echo "$DF_DATA" | awk '{print $2}')
    
    # Use bc for floating-point calculation and rounding to 2 decimal places (Base 10)
    # Formula: (BLOCKS * 1024) / (10^9) = GB (Decimal GB)
    
    # 2. Calculate TOTAL_GB 
    TOTAL_GB=$(echo "scale=2; $TOTAL_BLOCKS * 1024 / 1000000000" | bc)
    
    # --- APPLY RECALCULATION LOGIC TO MATCH GUI (Total = Used + Available) ---

    # 3. Calculate DF_AVAIL_GB: Get Available Blocks from df (Column 4) and convert.
    local AVAIL_BLOCKS=$(echo "$DF_DATA" | awk '{print $4}')
    local DF_AVAIL_GB=$(echo "scale=2; $AVAIL_BLOCKS * 1024 / 1000000000" | bc)

    # 4. Recalculate USED_GB: TOTAL - DF_AVAIL_GB (This corrects the 'Used' value)
    USED_GB=$(echo "scale=2; $TOTAL_GB - $DF_AVAIL_GB" | bc)

    # 5. Set AVAILABLE_GB: Ensure Available is the exact complement of Used and Total
    AVAIL_GB=$(echo "scale=2; $TOTAL_GB - $USED_GB" | bc)

    # Check for calculation errors 
    if ! [[ "$TOTAL_GB" =~ ^[0-9]+\.[0-9]+$ ]]; then TOTAL_GB="?"; fi
    if ! [[ "$USED_GB" =~ ^[0-9]+\.[0-9]+$ ]]; then USED_GB="?"; fi
    if ! [[ "$AVAIL_GB" =~ ^[0-9]+\.[0-9]+$ ]]; then AVAIL_GB="?"; fi
}

# RUN STORAGE CALCULATION FUNCTION
get_storage_details

# 3. FileVault Status (Simplified logic)
FV_RAW_STATUS=$(fdesetup status 2>/dev/null | head -n 1)
if [[ $FV_RAW_STATUS == "" ]]; then
    FV_STATUS="Unknown / Not checked (Requires sudo for full details)"
else
    if [[ $FV_RAW_STATUS == "FileVault is On." ]]; then
        FV_STATUS="FileVault is On"
    else
        FV_STATUS="FileVault is Off"
    fi
fi

# 4. Current User & User Type
CURRENT_USER=$USER
if id -Gn "$CURRENT_USER" | grep -q "admin"; then
    USER_TYPE="Admin"
else
    USER_TYPE="Standard"
fi

# 5. Apple ID Status (Checking for iCloud/MobileMe configuration existence)
APPLE_ID_CONFIG_COUNT=$(defaults read MobileMeAccounts Accounts 2>/dev/null | grep 'AccountID' | wc -l)

if [[ $APPLE_ID_CONFIG_COUNT -gt 0 ]]; then
    APPLE_ID_STATUS="Signed In"
else
    APPLE_ID_STATUS="Signed Out"
fi




TEXT_OUTPUT=$(cat <<-EOF
MACOS SYSTEM INFORMATION
==============================================
Device Model:           $DEVICE_MODEL
Chip:                   $CHIP_INFO
Memory (RAM):           $MEMORY_INFO
Serial Number:          $SERIAL_NUMBER
----------------------------------------------
Storage (Total GB):     ${TOTAL_GB} GB
Storage (Used GB):      ${USED_GB} GB
Storage (Available GB): ${AVAIL_GB} GB
FileVault Status:       $FV_STATUS
----------------------------------------------
Current User:           $CURRENT_USER
User Type:              $USER_TYPE
Apple ID Status:        $APPLE_ID_STATUS
==============================================
EOF
)


osascript -e "display dialog \"$(echo "$TEXT_OUTPUT" | tr '\n' '\r')\" with title \"MACOS SYSTEM INFO\" buttons {\"OK\"} default button \"OK\""