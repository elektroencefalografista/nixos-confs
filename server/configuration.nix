# TODO: we could PROBABLY move some of the critical services away from docker and into this: 
# 		- cloudflared but i like it on a separate network with all the shit thats running off of it
#		- ngrok maybe? no, needs python script to update cloudflare dns
#		- telegraf + prometheus, or at least telegraf. needs access to everything anyway
#		- maybe samba? nfs perchance? i like em in docker tho
#		- portainer??? perchance
# TODO section the config into files? sounds like pain. we also could:
# TODO download (import, fetchurl) parts from github maybe? i could easily put backuppers on git, would be the same for servre and rpi too
# i wonder if i can use fetchurl elsewhere
# tbh i could just have a common repo for all nixos, have a common.nix file, then include it. but we'd need to copy it over to the target os too huh
# TODO dkms for ryzen things, thats the only thing stopping me from moving. after that its just config cosmetics
# we could detect if its ryzen and only build if it is
# TODO completely disable getty login prompt at physical console, at least for rpi. its extra hardening and neat.

# FOR RPI
# TODO integrate config downloader/uploader/timer into rpi after its done (reads OS hostname and uploads to a correct folder based on that)
# TODO autoupdates. are they stable enough?

{ config, pkgs, ... }:

{
	imports = [
		./hardware-configuration.nix
		(fetchTarball "https://github.com/nix-community/nixos-vscode-server/tarball/master") # what do
		(builtins.fetchurl { url="https://raw.githubusercontent.com/elektroencefalografista/nixos-confs/main/common.nix"; })
	];

	########### BASICS and NETWORKING ###########

	boot = {
		loader = {
			systemd-boot.enable = true;
			efi.canTouchEfiVariables = true;
		};
		kernelModules = [ "nfs" "nfsd" "tun" ]; # not sure if i really need tun
		blacklistedKernelModules = [ "k10temp" ];
		# supportedFilesystems = [ "zfs" "btrfs" ]; # zfs not strictly needed? need 2 test
		# zfs.extraPools = [ "zpool" ];
		# kernelParams = [ "zfs.zfs_arc_min=0" "zfs.zfs_arc_max=1073741824" ]; # 1GB
	};

	networking = {
		hostName = "nox-test"; # Define your hostname.
		hostId = "5c932f77"; # for zfs, needs to be random
		networkmanager.enable = true;
		firewall.checkReversePath = "loose"; # suggested for tailscale
	};



	########### USERS, ENV VARS and SSH KEYS ###########
	
	environment.variables = {
		DOCKER_CONF_DIR = "$HOME/configs";
		TZ = "$(ls -l /etc/localtime | rev | cut -d \"/\" -f1-2 | rev)";
		EDITOR = "nano";
		XZ_DEFAULTS = "-T0";
		MAIN_NET_IFACE = "$(ip link | grep -Eo \"enp[1-9]s0\")";
	};


	########### FILESYSTEMS ########### should i move zfs here?

	# fileSystems = {
	# 	"/mnt/mfs_share" = {
	# 		# device = "/dev/disk/by-uuid/cdb15f8d-7a83-4b33-aaf7-e4147261900a";
	# 		device = "/dev/disk/by-uuid/243283da-bd51-4018-8177-2c9e35b6b30a";
	# 		fsType = "btrfs";
	# 		options = [ 
	# 			"relatime" 
	# 			"nofail"
	# 			"defaults"
	# 			"x-systemd.mount-timeout=15" ];
	# 	};

	# 	"/mnt/anime" = {
	# 		device = "/mnt/mfs_*:/mnt/zpool";
	# 		fsType = "fuse.mergerfs";
	# 		options = [ 
	# 			"defaults" 
	# 			"nonempty"
	# 			"allow_other"
	# 			"use_ino"
	# 			"category.create=msplfs"
	# 			"dropcacheonclose=true"
	# 			"minfreespace=10G"
	# 			"fsname=mfs_pool"
	# 			"nofail" ];
	# 		depends = [ "/mnt/zpool" "/mnt/mfs_anime" ];
	# 		noCheck = true;
	# 	};

	# };

	swapDevices = [ {
   		device = "/var/lib/swapfile";
    	size = 2*1024; # 2GB
 	} ];

	########### SOFTWARE and SERVICES ###########
	virtualisation.docker.enable = true;
	environment.systemPackages = with pkgs; [
		vim
		wget
		htop
		rclone # dont REALLY need it? since its defined in systemd pkgs anyway
		neofetch
		mergerfs
	];

	services = {
		tailscale.enable = true; # still need to join by hand but thats probably fine
		vscode-server.enable = true;
		zfs.autoScrub.enable = true;
	};

	##### CHANGE/COMMENT OUT THESE BEFORE DEPLOYING FOR REAL #####
	# services.getty.autologinUser = "drath";
	##############################################################



	systemd.user = {
		services = {
			oneshot-config-downloader = {
				enable = true;
				path = [ pkgs.pigz pkgs.gnutar pkgs.rclone ];
				after = [ "rclone-config-downloader.service" ];
				serviceConfig.Type = "oneshot";
				unitConfig.ConditionPathExists = "!%S/%N.stamp";
				serviceConfig.RemainAfterExit = "yes";
				scriptArgs = "%S %N server";
				script = ''
					mkdir -p $1
					rclone cat google:backup/$3/$3-docker-compose.tar.gz | pigz -d | tar -x -C ~ && \
					rclone cat google:backup/$3/$3-home-dir.tar.gz | pigz -d | tar -x -C ~ && \
					rclone cat google:backup/$3/$3-configs.tar.gz | pigz -d | tar -x -C ~ && \
					touch $1/$2.stamp
				'';
				description = "Download homedir files from google drive";
				wantedBy = [ "default.target" ];
			};
		};
	};

	system.stateVersion = "23.05";
}