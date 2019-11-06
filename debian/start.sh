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
	ssh-keygen -t rsa -b 4096 -C "$email"
	githubkey=$(cat /home/"$name"/.ssh/id_rsa.pub)
	curl -u "$githubuser" \
	    --data "{\"title\":\"DevVm_`date +%Y%m%d%H%M%S`\",\"key\":\"$githubkey\"}" \
	    https://api.github.com/user/keys
}

rinstall() {
	for app in $(cat "$1"); do
		# TODO: R install
	done
}

pipinstall() {
	for pythonapp in $(cat "$1"); do
		pip install "$pythonapp"
	done
}

scriptinstall() {
	for script in $(cat "$1"); do
		bash "$SCRIPTS/$script"
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
	curl -Ls "PATH/$1/progs" > /tmp/progs
	curl -Ls "PATH/$1/r" > /tmp/r
	curl -Ls "PATH/$1/python" > /tmp/python
	curl -Ls "PATH/$1/scripts" > /tmp/scripts

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

initialize || error "Error in intialize"
getuser || error "Error in intialize"
gitusermail || error "Error in intialize"
githubssh || error "Error in intialize"

case "$1" in
	"--laptop") laptopinstall;;
	"--pc") pcinstall;;
	"*") maininstall "general";;
esac







