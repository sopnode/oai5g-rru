#!/bin/bash
# This script aims to initialize the Quectel RM 500Q-GL device
# It has to be run once the device is switched on
# Else, it may not be able to connect correctly to OAI5G gNB


DEVICE=/dev/cdc-wdm0
HOME=/root

# First, switch off the radio
echo "---- mbimcli -p -d ${DEVICE} --set-radio-state=off"
mbimcli -p -d $DEVICE --set-radio-state=off

echo "sleep 5s"
sleep 5

# Second, set UE minimal functionality with AT+CFUN=0
echo "---- send command AT+CFUN=0"
$HOME/reset-ue

echo "sleep 5s"
sleep 5

# Then, switch on the radio
echo "---- mbimcli -p -d ${DEVICE} --set-radio-state=on"
mbimcli -p -d $DEVICE --set-radio-state=on

echo "sleep 20s"
sleep 20

# Finally, switch off the radio
echo "---- mbimcli -p -d ${DEVICE} --set-radio-state=off"
mbimcli -p -d $DEVICE --set-radio-state=off

echo "$0: init done, you can now use mbim-based start.sh/stop.sh commands"

