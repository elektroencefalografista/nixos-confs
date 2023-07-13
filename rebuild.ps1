if ( $args[0] -eq  "rpi" ) {
	$target = "drath@rpi"
	scp rpi/rpi.nix ${target}:~/.tmp
}

if ( $args[0] -eq "server" ) {
	$target = "drath@nix-test"
	scp server/configuration.nix ${target}:~/.tmp
}


ssh ${target} 'sudo mv ~/.tmp /etc/nixos/configuration.nix && sudo nixos-rebuild switch'