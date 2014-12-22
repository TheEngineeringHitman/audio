#!/bin/bash
clear
echo "################################################"
echo "## Script: setup_airplay.sh"
echo "## By: Andrew Herren"
echo "## Date: 11/07/14"
echo "## This script is based on a tutorial by Adam Burkepile which can be found at:"
echo "## www.raywenderlich.com/44918/raspberry-pi-airplay-tutorial"
echo "################################################"

echo -e "\nThis script will setup shairport which will allow you to use apple airplay with this pi. Would you like to continue? (y/n)>"
read answer

shopt -s nocasematch

case "$answer" in
y|yes )
	if [[ $(whoami) = "root" ]]; then
		echo "Would you like to update the sources list before continuing? (y/n)>"
		read sources
		echo "Would you like to perform a dist-upgrade before continuing? (y/n)>"
		read upgr
		echo "Would you like to perform autoremove to get rid of old/unused packages before continuing? (y/n)>"
		read autor
		case "$sources" in
		y|yes )
			echo "Performing update to sources list..."
			apt-get -q -y update
			;;
		* )
			echo "Skipping update to sources list..."
			;;
		esac
		case "$upgr" in
		y|yes)
			echo "Performing dist-upgrade..."
			apt-get -q -y dist-upgrade
			;;
		* )
			echo "Skipping dist-upgrade..."
			;;
		esac
		case "$autor" in
		y|yes )
			echo "Performing autoremove..."
			apt-get -q -y autoremove
			;;
		* )
			echo "Skipping autremove..."
			;;
		esac
		amixer cset numid=3 1
		apt-get -q -y install git libao-dev libssl-dev libcrypt-openssl-rsa-perl libio-socket-inet6-perl libwww-perl avahi-utils libmodule-build-perl
		mkdir /bin/airplay
		orig_dir=$pwd
		cd /bin/airplay
		git clone https://github.com/njh/perl-net-sdp.git perl-net-sdp
		cd perl-net-sdp
		perl Build.PL
		./Build
		./Build test
		./Build install
		cd ..
		git clone https://github.com/hendrikw82/shairport.git
		cd shairport
		make install
		air_name=$(awk '/./{print $0}' /etc/hostname)
		awk -v air_name="$air_name" '{if($0~/DAEMON_ARGS=/)print "DAEMON_ARGS=\"-w $PIDFILE -a "airname"\"";else print $0;}' shairport.init.sample > /etc/init.d/shairport
		chmod a+x /etc/init.d/shairport
		update-rc.d shairport defaults
		cd $orig_dir
		echo "Setup complete. Airplay should be available as "$air_name" after a reboot."
		echo "Would you like to reboot now? (y/n)>"
		read autoreboot
		case "$autoreboot" in
		y|yes )
			echo "System rebooting..."
			shutdown -r now
			;;
		* )
			echo "Skipping reboot. Please remember that you will need to reboot before shairport is functional."
			;;
		esac
	else
		echo "This script must be run as root. Please try again using sudo."
	fi
	;;
* )	
	echo "Exiting without changes..."
	;;
esac
shopt -u nocasematch
