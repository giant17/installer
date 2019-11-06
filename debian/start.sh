#!/bin/sh

error() { clear; printf "ERROR:\\n%s\\n" "$1"; exit;}

initialize() {
	apt-get update
	apt-get upgrade -y
	apt-get install -y curl git hub python3-pip python-pip
}

getuser() {
	read -p "Enter username: " name
	while true; do
		if cat /etc/passwd | grep -q "$name"; then
			echo "$name is a valid username"
			break
		else
			read -p "Username not found. Please retry : " name
		fi
	done

	usermod -aG sudo "$name"
}

gitusermail() {
	read -p "Enter GitHub username: " githubuser
	read -p "Enter mail : " email
}

githubssh() {
	sudo -u "$name" ssh-keygen -t rsa -b 4096 -C "$email"
	githubkey=$(cat /home/"$name"/.ssh/id_rsa.pub)
	hostname=$(cat /proc/sys/kernel/hostname)
	curl -u "$githubuser" \
	    --data "{\"title\":\"$hostname\",\"key\":\"$githubkey\"}" \
	    https://api.github.com/user/keys
}

rinstall() {
	for app in $(cat "$1"); do
		sudo R -e 'install.packages("'$app'",repos="http://cran.us.r-project.org")'
	done
}

pipinstall() {
	for pythonapp in $(cat "$1"); do
		pip install "$pythonapp"
	done
}

scriptinstall() {
	for script in $(cat "$1"); do
		bash /tmp/scripts_folder/$script
	done
}

aptinstall() {
	for app in $(cat "$1"); do
		apt-get install -y "$app"
	done
}

serviceinstall() {
	for service in $(cat "$1"); do
		systemctl enable "$service"
		systemctl start "$service"
	done
}

systembeepoff() {
	rmmod pcspkr
	echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
}

maininstall() {
	hub clone installer /tmp/installer
	cp /tmp/installer/debian/progs/$1/* /tmp

	cp -r /tmp/installer/debian/scripts /tmp/scripts_folder

	aptinstall /tmp/progs
	rinstall /tmp/r
	pipinstall /tmp/python
	scriptinstall /tmp/scripts
}

laptopinstall() {
	maininstall "general"
	maininstall "laptop"
}

laptopinstall() {
	maininstall "general"
	maininstall "pc"
}

HOME="/home/$name"

initialize || error "Error in intialize"
getuser || error "Error in getuser"
gitusermail || error "Error in gitusermail"
githubssh || error "Error in githubssh"

case "$1" in
	"--laptop") laptopinstall;;
	"--pc") pcinstall;;
	"*") maininstall "general";;
esac

systembeepoff || error "Error in systembeepoff."





