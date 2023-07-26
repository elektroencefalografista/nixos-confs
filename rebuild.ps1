if ( $args[0] -eq  "rpi" ) {
	$target = "drath@rpi"
	scp rpi/rpi.nix ${target}:~/.tmp
}

if ( $args[0] -eq "server" ) {
	$target = "drath@server"
	scp server/configuration.nix ${target}:~/.tmp
}

if ( $args[0] -eq "atom" ) {
	$target = "drath@atom"
	scp atom/configuration.nix ${target}:~/.tmp
}

if ( $args[0] -eq "test" ) {
	$target = "drath@172.26.46.236"
	scp server/conf2.nix ${target}:~/.tmp
}

scp common.nix ${target}:~/.tmp2
ssh ${target} 'sudo mv ~/.tmp /etc/nixos/configuration.nix && sudo mv ~/.tmp2 /etc/nixos/common.nix && sudo nixos-rebuild switch'