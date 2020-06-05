#!/bin/bash

# esp_flasher.sh - ESP82xx Flasher Helper Script
# 
#	Just a simple script to save some typing while holding jumper wires.
#	This script will take you though the steps of backing up, erasing, 
#	and flashing an ESP82xx device using esptool.py


# Adjust variables as needed.
PACKAGE="esp_flasher.sh"
ESPTOOL=$(which esptool.py)
PORT="/dev/ttyUSB0"
FLASH_MODE="dout"
FLASH_SIZE="1MB"
MEMSTART="0x00000"
MEMEND="0x10000"  # 1MB Flash


# Get args
while test $# -gt 0; do
	case "$1" in
		-h|--help)
			echo
			echo "$PACKAGE - ESP Flasher Helper Script"
			echo
			echo "Just a simple script to save some typing while holding jumper wires."
			echo "This script will take you though the steps of backing up, erasing, "
			echo "and flashing an ESP82xx device using esptool.py"
			echo 
			echo "IMPORTANT: Make sure your ESP82xx board is in Flash Mode"
			echo "           for each step or this script will fail."
			echo
			echo "Usage: $PACKAGE [options]"
			echo
			echo "Options:"
			echo "  -h, --help                      Show this help"
			echo "  -a, --auto                      Automatically moves on to the next step."
			echo "                                  Useful if your device has a built in USB programmer."
			echo "                                  (Example: WeMOs D1 Mini)"
			echo "  -b, --backup=filename.bin       Backup the existing firmware."
			echo "  -e, --erase                     Erase the flash on the device."
			echo "  -f, --firmware=filename.bin     Firmware to flash to device."
			echo
			exit 0
			;;
		-a)
			export AUTO_MODE=1
			shift
			;;
		-b)
			shift
			if test $# -gt 0; then
				if [ $1 == '-f' ] || [ $1 == '-e' ]; then
					echo "No backup file specified."
					exit 1
				else
				  export BACKUP_FILE=$1
				fi
			else
				echo
				echo "No backup file specified."
				exit 1
			fi
			shift
			;;
		--backup*)
			BACKUP_FILE=$(echo $1 | sed -e 's/^[^=]*=//g')
			export BACKUP_FILE
			;;
		-e)
			export ERASE_FLASH=1
			shift
			;;
		--erase)
			export ERASE_FLASH=1
			;;
		-f)
			shift
			if test $# -gt 0; then
				export FIRMWARE_FILE=$1
			else
				echo
				echo "Error: No firmware file specified"
				exit 1
			fi
			shift
			;;
		--firmware*)
			if test $# -gt 0; then
				FIRMWARE_FILE=$(echo $1 | sed -e 's/^[^=]*=//g')
				export FIRMWARE_FILE
			fi
			shift
			;;
		*)
			break
			;;
	esac
done


function fw_backup() {
	cmnd="$ESPTOOL -p $PORT read_flash $MEMSTART $MEMEND $BACKUP_FILE"
	echo
	echo "---------------"
	echo "Backup firmware"
	echo "---------------"
	echo
	echo "This will make a backup of the device firmware with the name $BACKUP_FILE by executing:"
	echo "$cmnd"
	echo
	echo "Make sure your ESP82xx device is in Flash Mode."
	echo
	if [ ! -v AUTO_MODE ]; then
		read -p "Press ENTER when ready or CTRL-C to exit"
	fi
	echo
	$cmnd
	echo "(Pausing for reset)."
	sleep 4
	if [ -v ERASE_FLASH ]; then
		fw_erase
	else
		exit 0
	fi
}

function fw_erase() {
	cmnd="$ESPTOOL -p $PORT erase_flash"
	echo
	echo "--------------"
	echo "Erase Firmware"
	echo "--------------"
	echo
	echo "This will delete the current firmware on the device at $PORT by executing:"
	echo "$cmnd"
	echo
	echo "Make sure your ESP82xx device is in Flash Mode."
	echo
	if [ ! -v AUTO_MODE ]; then
		read -p "Press ENTER when ready or CTRL-C to exit"
	fi
	echo
	$cmnd
	echo "(Pausing for reset)."
	sleep 4
	if [ -v FIRMWARE_FILE ]; then
		fw_flash
	else
		exit 0
	fi
}

function fw_flash() {
	cmnd="$ESPTOOL -p $PORT write_flash -fs $FLASH_SIZE -fm $FLASH_MODE $MEMSTART $FIRMWARE_FILE"
	echo
	echo "--------------"
	echo "Flash Firmware"
	echo "--------------"
	echo
	echo "This will flash $FIRMWARE_FILE to the device at $PORT by executing:"
	echo "$cmnd"
	echo
	echo "Make sure you have already erased the existing flash on the device."
  echo "If not, exit this script with CTRL-C and rerun this script with the '-e' flag."
	echo
	echo "Make sure your ESP82xx device is in Flash Mode."
	echo
	if [ ! -v AUTO_MODE ]; then
		read -p "Press ENTER when ready or CTRL-C to exit"
	fi
	echo
	$cmnd
	echo
	echo "Reboot your device in Normal Mode to use your new firmware."
	exit 0
}

# Run
if [ -v BACKUP_FILE ]; then
	fw_backup
elif [ -v ERASE_FLASH ]; then
	fw_erase
elif [ -v FIRMWARE_FILE ]; then
	fw_flash
else
	echo "No options given"
	echo "Run $PACKAGE -h"
	exit 0
fi
