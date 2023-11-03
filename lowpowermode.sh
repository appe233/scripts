#!/bin/bash
# macOS
# run the script to toggle low power mode
LOW_POWER_MODE=`pmset -g | sed -n "14p" | grep -o "[01]"`
if [ $LOW_POWER_MODE == "1" ]
then
	pmset -a lowpowermode 0
else
	pmset -a lowpowermode 1
fi
