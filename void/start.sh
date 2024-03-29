#!/bin/sh
# Luke's Auto Rice Boostrapping Script (LARBS)
# by Luke Smith <luke@lukesmith.xyz>
# License: GNU GPLv3

### OPTIONS AND VARIABLES ###

while getopts ":r:p:b:h" o; do case "${o}" in
	h) printf "Optional arguments for custom use:\\n  -r: Dotfiles repository (local file or url)\\n  -b: Dotfiles branch (master is assumed otherwise)\\n  -p: Dependencies and programs csv (local file or url)\\n  -h: Show this message\\n" && exit ;;
	r) dotfilesrepo=${OPTARG} && git ls-remote "$dotfilesrepo" || exit ;;
	b) repobranch=${OPTARG} ;;
	p) progsfile=${OPTARG} ;;
	*) printf "Invalid option: -%s\\n" "$OPTARG" && exit ;;
esac done

# DEFAULTS:
[ -z "$dotfilesrepo" ] && dotfilesrepo="https://github.com/giant17/dotfiles"
[ -z "$progsfile" ] && progsfile="https://raw.githubusercontent.com/giant17/installer/master/progs.csv"
[ -z "$repobranch" ] && repobranch="master"

### FUNCTIONS ###

error() { clear; printf "ERROR:\\n%s\\n" "$1"; exit;}

welcomemsg() { \
	dialog --title "Welcome!" --msgbox "Welcome to Luke's Auto-Rice Bootstrapping Script!\\n\\nThis script will automatically install a fully-featured i3wm Void Linux desktop, which I use as my main machine.\\n\\n-Luke" 10 60
	}

getuser() { \
	name=$(dialog --inputbox "First, please enter a name for the user account for which you'd like to install LARBS." 10 60 3>&1 1>&2 2>&3 3>&1) || exit
	while ! echo "$name" | grep "^[a-z_][a-z0-9_-]*$" >/dev/null 2>&1; do
		name=$(dialog --no-cancel --inputbox "Username not valid. Give a username beginning with a letter, with only lowercase letters, - or _." 10 60 3>&1 1>&2 2>&3 3>&1)
	done
	! (id -u "$name" >/dev/null) 2>&1 &&
		dialog --title "Create user first then re-run script" --msgbox "Please create your user and password before running LARBS. Note that you can use the user you created in the Void Linux installation process.\\n\\nIf you want to make a new user, you will want to run a command like this, adding your user to all the needed groups and creating a home directory:\\n\\n$ useradd -m -G wheel,users,audio,video,cdrom,input -s /bin/bash <user>\\n$ passwd <user>" 14 75 && exit
	return 0 ;}


githubuser() { \
	gituser=$(dialog --inputbox "First, please enter a name for the user account for which you'd like to install LARBS." 10 60 3>&1 1>&2 2>&3 3>&1) || exit
	while ! echo "$name" | grep "^[a-z_][a-z0-9_-]*$" >/dev/null 2>&1; do
		gituser=$(dialog --no-cancel --inputbox "GitHub user not valid. Give a username beginning with a letter, with only lowercase letters, - or _." 10 60 3>&1 1>&2 2>&3 3>&1)
	done
	}

getmailuser() { \
	name=$(dialog --inputbox "First, please enter a name for the user account for which you'd like to install LARBS." 10 60 3>&1 1>&2 2>&3 3>&1) || exit
	while ! echo "$mailuser" | grep "^[a-z_][a-z0-9_-]*$" >/dev/null 2>&1; do
		name=$(dialog --no-cancel --inputbox "Mail not valid" 10 60 3>&1 1>&2 2>&3 3>&1)
	done
	}

preinstallmsg() { \
	dialog --title "Let's get this party started!" --yes-label "Let's go!" --no-label "No, nevermind!" --yesno "The rest of the installation will now be totally automated, so you can sit back and relax.\\n\\nIt will take some time, but when done, you can relax even more with your complete system.\\n\\nNow just press <Let's go!> and the system will begin installation!" 13 60 || { clear; exit; }
	}

maininstall() { # Installs all needed programs from main repo.
	dialog --title "LARBS Installation" --infobox "Installing \`$1\` ($n of $total). $1 $2" 5 70
	xbps-install -y "$1" >/dev/null 2>&1
	}

gitmakeinstall() {
	repo="$(basename "$1")"
	repodir="/home/$name/repos/forks/$repo"
	dialog --title "LARBS Installation" --infobox "Installing \`$(basename "$1")\` ($n of $total) via \`git\` and \`make\`. $(basename "$1") $2" 5 70
	sudo -u "$name" mkdir -p "$repodir"
	sudo -u "$name" git clone --depth 1 "$1" "/home/$name/repos/forks/$repo" >/dev/null 2>&1
	cd "$repodir" || exit
	make install >/dev/null 2>&1
	cd /tmp || return ;}

pipinstall() { \
	dialog --title "LARBS Installation" --infobox "Installing the Python package \`$1\` ($n of $total). $1 $2" 5 70
	command -v pip3 || xbps-install -Sy python3-pip >/dev/null 2>&1
	yes | sudo -u "$name" pip3 install --user "$1"
	}

sshgithub() { \
	ssh-keygen -t rsa -b 4096 -C "$mailuser"
	curl -u "user:pass" --data '{"title":"test-key","key":"'"$(cat ~/.ssh/id_rsa.pub)"'"}' https://api.github.com/user/keys
	}


installationloop() { \
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" | sed '/^#/d' > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)
	while IFS=, read -r tag program comment; do
		n=$((n+1))
		echo "$comment" | grep "^\".*\"$" >/dev/null 2>&1 && comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"
		case "$tag" in
			"") maininstall "$program" "$comment" ;;
			"G") gitmakeinstall "$program" "$comment" ;;
			"P") pipinstall "$program" "$comment" ;;
		esac
	done < /tmp/progs.csv ;}

putgitrepo() { # Downlods a gitrepo $1 and places the files in $2 only overwriting conflicts
	[ -z "$3" ] && branch="master" || branch="$repobranch"
	dialog --infobox "Downloading and installing config files..." 4 60
	sudo -u "$name" mkdir -p "/home/$name/repos/linux"
	sudo -u "$name" git clone "$1" "/home/$name/repos/linux/dotfiles"
	cd "/home/$name/repos/linux/dotfiles"
	rm "/home/$gian/.bashrc"
	rm "/home/$gian/.bash_profile"
	rm "/home/$gian/.inputrc"
	sudo -u "$name" stow -vt "/home/$name" *
	}

serviceinit() { for service in "$@"; do
	dialog --infobox "Enabling \"$service\"..." 4 40
	ln -s "/etc/sv/$service" /var/service/
	sv start "$service"
	done ;}

systembeepoff() { dialog --infobox "Getting rid of that retarded error beep sound..." 10 50
	rmmod pcspkr
	echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf ;}

finalize(){ \
	dialog --infobox "Preparing welcome message..." 4 50
	echo "exec_always --no-startup-id notify-send -i ~/.scripts/larbs.png 'Welcome to LARBS:' 'Press Super+F1 for the manual.' -t 10000"  >> "/home/$name/.config/i3/config"
	dialog --title "All done!" --msgbox "Congrats! Provided there were no hidden errors, the script completed successfully and all the programs and configuration files should be in place.\\n\\nTo run the new graphical environment, log out and log back in as your new user, then run the command \"startx\" to start the graphical environment (it will start automatically in tty1).\\n\\n.t Luke" 12 80
	}

### THE ACTUAL SCRIPT ###

### This is how everything happens in an intuitive format and order.

# Check if user is root on Arch distro. Install dialog.
xbps-install -Syu dialog

# Welcome user.
welcomemsg || error "User exited."

# Get and verify username and password.
getuser || error "User exited."

# Last chance for user to back out before install.
preinstallmsg || error "User exited."

### The rest of the script requires no user input.

dialog --title "LARBS Installation" --infobox "Installing \`basedevel\` and \`git\` for installing other software." 5 70
xbps-install -y curl base-devel git >/dev/null 2>&1

# The command that does all the installing. Reads the progs.csv file and
# installs each needed program the way required. Be sure to run this only after
# the user has been created and has priviledges to run sudo without a password
# and all build dependencies are installed.
installationloop

# Install the dotfiles in the user's home directory
#putgitrepo "$dotfilesrepo" "/home/$name" "$repobranch"
#rm -f "/home/$name/README.md" "/home/$name/LICENSE"

# Enable services here.
serviceinit wpa_supplicant dbus crond acpid thermald

# Most important command! Get rid of the beep!
systembeepoff

# Last message! Install complete!
finalize
clear
