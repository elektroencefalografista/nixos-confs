#!/bin/sh
HOST=drath@192.168.1.1

scp -o StrictHostKeychecking=no rpi.nix ${HOST}:~/.tmp
ssh -o StrictHostKeychecking=no ${HOST} 'bash -s' << EOF
	sudo cp ~/.tmp /etc/nixos/configuration.nix
	sudo nixos-rebuild switch
EOF
