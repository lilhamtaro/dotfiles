#!/bin/bash

# Dependencies: wpctl, bluetoothctl, notify-send

# Define a list of preferred mic-capable profiles (order matters)
PREFERRED_PROFILES=("handsfree_head_unit" "headset_head_unit" "hsp_hs" "hfp_hf")

# Get list of connected Bluetooth audio devices
CONNECTED_MACS=$(bluetoothctl devices | grep -E "Device" | awk '{print $2}')

for MAC in $CONNECTED_MACS; do
  # Skip if not connected
  if ! bluetoothctl info "$MAC" | grep -q "Connected: yes"; then
    continue
  fi

  # Get device alias
  DEVICE_ALIAS=$(bluetoothctl info "$MAC" | grep "Name:" | cut -d ' ' -f2-)

  # Find corresponding wpctl device ID
  AUDIO_NODE_LINE=$(wpctl status | grep "$DEVICE_ALIAS" | grep "Audio/Sink")
  NODE_ID=$(echo "$AUDIO_NODE_LINE" | awk -F'.' '{print $1}' | awk '{print $NF}')

  if [[ -z "$NODE_ID" ]]; then
    notify-send "Bluetooth Mic Fix" "No audio sink found for $DEVICE_ALIAS ($MAC)"
    continue
  fi

  # Get list of available profiles
  PROFILES=$(wpctl inspect "$NODE_ID" | grep "profiles:" -A 20 | awk '/properties:/ {exit} {print}' | grep -oE 'profile\..*')

  PROFILE_SET=0
  for PROFILE_NAME in "${PREFERRED_PROFILES[@]}"; do
    if echo "$PROFILES" | grep -q "$PROFILE_NAME"; then
      wpctl set-profile "$NODE_ID" "$PROFILE_NAME" && \
        notify-send "Bluetooth Mic Fix" "Mic profile '$PROFILE_NAME' set for $DEVICE_ALIAS" || \
        notify-send "Bluetooth Mic Fix" "Failed to set '$PROFILE_NAME' for $DEVICE_ALIAS"
      PROFILE_SET=1
      break
    fi
  done

  if [[ $PROFILE_SET -eq 0 ]]; then
    notify-send "Bluetooth Mic Fix" "No valid mic-capable profile found for $DEVICE_ALIAS"
  fi
done
