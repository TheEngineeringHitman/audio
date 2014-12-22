#!/bin/bash
clear
echo "################################################"
echo "## Script: setup_pandora.sh"
echo "## By: Andrew Herren"
echo "## Date: 11/13/2014"
echo "## This script is based on an instructable by Ayy that can be found at:"
echo "## www.inistructables.com/id/Pandoras-Box-An-Internet-Radio-player-made-with/step3/Installing-Pianobar/"
echo "## and a blog post by lanmaster found at:
echo "## www.lanmaster53.com/2014/05/raspberry-pi-pianobar
echo "################################################"

cur_dir=$pwd
shopt -s nocasematch
echo -e "\nThis script will setup pianobar which will allow you to play pandora from your Pi."
echo "Would you like to continue? (y/n)>"
read answer
case "$answer" in
y|yes )
	if [[ $(whoami) = "root" ]]; then
		echo "Would you like to update the sources list before continuing? (y/n)>"
		read sources
		echo "Would you like to perform a dist-upgrade before continuing? (y/n)>"
		read upgr
		echo "Would you like to perform autoremove to get rid of old/unused packages before continuing? (y/n)>"
		read autor
		echo "Would you like pianobar to automatically log you in when it starts? If yes, this will store your pandora login"
		echo "credentials in plain text in the config file. (y/n)>"
		read autologin
		case "$autologin" in
		y|yes )
			echo "Enter your pandora username (email). >"
			read username
			echo "Enter your pandora password. >"
			read password
			echo "Enter the user account that you will use to login to the Pi so I knwo where to save the config file. >"
			read user_account
			;;
		* )
			echo "Automatic login will remain disabled."
			echo "Would you like to create a default config file for pianobar? (y/n)>"
			read dfcfg
			case "$dfcfg" in
			y|yes )
				echo "Please enter the Pi's username that you would like to create the config file for. >"
				read user_account
				;;
			* )
				echo "No config file will be created."
				;;
			esac
			;;
		esac
		echo "Would you like to install pandora from the debian repositories or compile from source? Press r for repos or c for compile. >"
		read compFromSrc
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
		case "$compFromSrc" in
		c )
			echo "Installing from source. This will take about 15-20 minutes."
			apt-get -y -q install git libao-dev libgcrypt11-dev libgnutls-dev libfaad-dev libmad0-dev libjson0-dev make pkg-config
			git clone https://github.com/FFmpeg/FFmpeg.git
			cd FFmpeg
			./configure --enable-shared --disable-everything --enable-demuxer=mov --enable-decoder=aac --enable-protocol=http --enable-filter=volume --enable-filter=aformat --enable-filter=aresample --disable-programs --disable-doc
			make clean
			make
			make install
			cd $cur_dir
			git clone https://github.com/PromyLOPh/pianobar.git
			cd pianobar
			make clean
			make
			make install
			;;
		* )	
			echo "Installing from repositiories."
			apt-get -y -q install pianobar
			;;
		esac
		mv /usr/share/alsa/alsa.conf /usr/share/alsa/alsa.conf.old
		awk '//{if($0~/pcm\.front cards\.pcm\.front/){print "pcm.front cards.pcm.default"}else{print $0}}' /usr/share/alsa/alsa.conf.old > /usr/share/alsa/alsa.conf
		echo "LD_LIBRARY_PATH=/usr/local/lib" >> /etc/environment
		echo "alias pandora='pianobar'" >> /etc/profile
		export LD_LIBRARY_PATH=/usr/local/lib
		if [[ $user_account != "" ]]; then
			tls=$(openssl s_client -connect tuner.pandora.com:443 < /dev/null 2> /dev/null | openssl x509 -noout -fingerprint | tr -d ':' | cut -d'=' -f2)
			mkdir -p /home/$user_account/.config/pianobar
			pianobar="/home/"$user_account"/.config/pianobar/config"
			echo "# This is an example configuration file for pianobar. You may remove the # from" >> $pianobar
			echo "# lines you need and copy/move this file to ~/.config/pianobar/config" >> $pianobar
			echo "# See manpage for a description of the config keys" >> $pianobar
			echo "#" >> $pianobar
			echo "# User" >> $pianobar
			if [[ "$username" != "" ]]; then
				echo "user = "$username >> $pianobar
				echo "password = "$password >> $pianobar
			else
				echo "#user = email" >> $pianobar
	                        echo "#password = password" >> $pianobar
			fi
			echo "# or" >> $pianobar
			echo "#password_command = gpg --decrypt ~/password" >> $pianobar
			echo "" >> $pianobar
			echo "# Proxy (for those who are not living in the USA)" >> $pianobar
			echo "#control_proxy = http://127.0.0.1:9090/" >> $pianobar
			echo "" >> $pianobar
			echo "# Keybindings" >> $pianobar
			echo "act_help = ?" >> $pianobar
			echo "act_songlove = +" >> $pianobar
			echo "act_songban = -" >> $pianobar
			echo "act_stationaddmusic = a" >> $pianobar
			echo "act_stationcreate = c" >> $pianobar
			echo "act_stationdelete = d" >> $pianobar
			echo "act_songexplain = e" >> $pianobar
			echo "act_stationaddbygenre = g" >> $pianobar
			echo "act_songinfo = i" >> $pianobar
			echo "act_addshared = j" >> $pianobar
			echo "act_songmove = m" >> $pianobar
			echo "act_songnext = n" >> $pianobar
			echo "act_songpause = p" >> $pianobar
			echo "act_quit = q" >> $pianobar
			echo "act_stationrename = r" >> $pianobar
			echo "act_stationchange = s" >> $pianobar
			echo "act_songtired = t" >> $pianobar
			echo "act_upcoming = u" >> $pianobar
			echo "act_stationselectquickmix = x" >> $pianobar
			echo "act_voldown = (" >> $pianobar
			echo "act_volup = )" >> $pianobar
			echo "" >> $pianobar
			echo "# Misc" >> $pianobar
			echo "#audio_quality = low" >> $pianobar
			echo "#autostart_station = 123456" >> $pianobar
			echo "#event_command = /home/$user_account/.config/pianobar/scripts/eventcmd.sh" >> $pianobar
			echo "#fifo = /home/$user_account/.config/pianobar/ctl" >> $pianobar
			echo "#sort = quickmix_10_name_az" >> $pianobar
			echo "#love_icon = [+]" >> $pianobar
			echo "#ban_icon = [-]" >> $pianobar
			echo "#volume = 0" >> $pianobar
			echo "" >> $pianobar
			echo "# Format strings" >> $pianobar
			echo "#format_nowplaying_song = " >> $pianobar
			echo "n %" >> $pianobar
			echo "#format_nowplaying_station = Stationmt_list_song = %i) %a - %t%r" >> $pianobar
			echo "" >> $pianobar
			echo "# high-quality audio (192k mp3, for Pandora One subscribers only!)" >> $pianobar
			echo "#audio_quality = high" >> $pianobar
			echo "#rpc_host = internal-tuner.pandora.com" >> $pianobar
			echo "#partner_user = pandora one" >> $pianobar
			echo "#partner_password = TVCKIBGS9AO9TSYLNNFUML0743LH82D" >> $pianobar
			echo "#device = D01" >> $pianobar
			echo "#encrypt_password = 2%3WCL*JU$MP]4" >> $pianobar
			echo "#decrypt_password = U#IO$RZPAB%VX2" >> $pianobar
			echo "tls_fingerprint = "$tls >> $pianobar
		fi
		echo "Pianobar setup is now complete. A reboot is required for pianobar to run without errors."
		echo "I have also created an alias in /etc/profile so that you can start the program by typing"
		echo "either pianobar or pandora. Would you like to reboot now? (y/n)>"
		read pb_reboot
		case "$pb_reboot" in
		y|yes )	
			echo "restarting now..."
			shutdown -r now
			;;
		* )
			echo "Skipping reboot. Please remember to restart before running pianobar or you will see errors."
			;;
		esac
	else
		echo "This script must be run as root. Please try again using sudo."
	fi
	;;
* )	
	echo "Exiting without changes."
	;;
esac
shopt -u nocasematch
