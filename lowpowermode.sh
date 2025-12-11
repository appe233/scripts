#!/bin/bash

# macOS
# run the script to toggle low power mode

CURRENT_MODE=$(pmset -g | grep "lowpowermode" | awk '{print $2}')

if [ $CURRENT_MODE == "1" ]
then
	sudo pmset -a lowpowermode 0
else
	sudo pmset -a lowpowermode 1
fi
