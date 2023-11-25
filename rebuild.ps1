$nix_user = "drath"
$nix_host = $args[0]

scp .\${nix_host}\configuration.nix .\common.nix .\secrets.nix ${nix_user}@${nix_host}:~/.cache
ssh ${nix_user}@${nix_host} 'sudo mv -v ~/.cache/*.nix /etc/nixos/ && sudo nixos-rebuild switch'