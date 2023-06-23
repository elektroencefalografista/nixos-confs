if ( $args[0] -eq  "rpi" ) {
	$target = "drath@192.168.1.1"
	scp rpi/rpi.nix ${target}:~/.tmp
}

if ( $args[0] -eq "server" ) {
	$target = "drath@192.168.1.2"
	scp server/configuration.nix ${target}:~/.tmp
}


ssh ${target} 'sudo mv ~/.tmp /etc/nixos/configuration.nix && sudo nixos-rebuild switch'