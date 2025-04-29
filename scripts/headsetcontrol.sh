#!/bin/bash

# Script for controlling headset sidetone and displaying battery level
# Works with waybar custom module

SIDETONE_FILE="$HOME/.config/waybar/scripts/headset_sidetone_value"
MAX_VALUE=128
MIN_VALUE=0
STEP=4

# Initialize sidetone value if file doesn't exist
if [ ! -f "$SIDETONE_FILE" ]; then
    # Try to get current sidetone value (this might not be supported by all headsets)
    current=$(headsetcontrol -g 2>/dev/null | grep -oP 'Current sidetone: \K[0-9]+' || echo 64)
    echo "$current" > "$SIDETONE_FILE"
fi

current_value=$(cat "$SIDETONE_FILE")

# Function to apply sidetone setting
apply_sidetone() {
    local value=$1
    headsetcontrol -s "$value" >/dev/null 2>&1
    echo "$value" > "$SIDETONE_FILE"
}

# Get battery level
get_battery() {
    battery_output=$(headsetcontrol -b 2>/dev/null)
    
    # Check if battery output contains "Level: X%" format
    level=$(echo "$battery_output" | grep -oP 'Level: \K[0-9]+(?=%)' 2>/dev/null)
    
    # If we found a level, return it with % symbol
    if [ -n "$level" ]; then
        echo "$level%"
    else
        # Fall back to old handling for backward compatibility
        case "$battery_output" in
            "-1")
                echo "Unknown"
                ;;
            "-2")
                echo "Not supported"
                ;;
            *)
                # If it's just a number, use it directly
                if [[ "$battery_output" =~ ^[0-9]+$ ]]; then
                    echo "$battery_output%"
                else
                    echo "Unknown"
                fi
                ;;
        esac
    fi
}

# Handle actions
case "$1" in
    "increase")
        new_value=$((current_value + STEP))
        if [ "$new_value" -gt "$MAX_VALUE" ]; then
            new_value=$MAX_VALUE
        fi
        apply_sidetone "$new_value"
        ;;
    "decrease")
        new_value=$((current_value - STEP))
        if [ "$new_value" -lt "$MIN_VALUE" ]; then
            new_value=$MIN_VALUE
        fi
        apply_sidetone "$new_value"
        ;;
    "set")
        # Set to specific value if provided
        if [ -n "$2" ] && [ "$2" -ge "$MIN_VALUE" ] && [ "$2" -le "$MAX_VALUE" ]; then
            apply_sidetone "$2"
        fi
        ;;
    "json")
        # Output JSON for waybar
        battery=$(get_battery)
        echo '{"text": "🎤 '$current_value' 🔋 '$battery'", "tooltip": "Sidetone: '${current_value}' \nBattery: '$battery'"}'
        ;;
    *)
        echo "Sidetone: $current_value/$MAX_VALUE"
        echo "Battery: $(get_battery)"
        ;;
esac
