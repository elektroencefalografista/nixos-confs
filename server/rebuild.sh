#!/bin/sh
HOST=drath@nox-test.lan

scp -o StrictHostKeychecking=no configuration.nix ${HOST}:~/.tmp
ssh -o StrictHostKeychecking=no ${HOST} 'bash -s' << EOF
	sudo cp ~/.tmp /etc/nixos/configuration.nix
	sudo nixos-rebuild switch
EOF
