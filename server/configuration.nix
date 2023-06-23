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
# TODO bashrc.d loading if it doesnt already?
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

	i18n.defaultLocale = "pl_PL.UTF-8"; # need to be set explicitly
	time.timeZone = "Europe/Warsaw";

	networking = {
		hostName = "nox-test"; # Define your hostname.
		hostId = "5c932f77"; # for zfs, needs to be random
		networkmanager.enable = true;
		firewall.checkReversePath = "loose"; # suggested for tailscale
	};



	########### USERS, ENV VARS and SSH KEYS ###########

	security.sudo.wheelNeedsPassword = false; # appearently thats outdated
	users.users.drath = {
		isNormalUser = true;
		description = "drath";
		extraGroups = [ "networkmanager" "wheel" "docker" ];
		hashedPassword= "$y$j9T$bnjLbA/0fVbi7aAbrAPbS/$LjSoS.ipo.ceLyJA0t/E1ZgAj68cNhloUC0hVBBMdU5";
		openssh.authorizedKeys.keys = [
			"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSbAgVbfQZJFrI1i3NnCPHJRAfB4b/f7/pjE3T/7RvaLUH0vd7PR1PtvHkMl6vGJULVBA7coXjmlb1mJ/NPCsjdJg71VxJD2Wjm0lFeyPnm41aCHn3Pi7vbyib9i8xaZtflxkufpjrAZ/PeKNxMivIdFySH3aKelkvNYoTjGj4+oPhzpRTu1TJinAtqJACSvY4z0zNbADW1QqFabuRet8oCAUnWeMKTUrX1h+TSNOCo7BAM7EMaWl7+Wuahc4uAWuAhTcPmxJMW50G4WWxexdyy8sSUnrbH+ohgwkS/ZnePelDApfbIPkBDW0vKoVXKjTSDgm9awEHscVqF6OZv+lC8tZ10WjBHIC+tLLEAHTkSSIJM3XBsl9ohEmPmlbcz7tWaM5x12XLDMVgzT9cus/ArMmrpY091FRGZWr6GQH5YTfzPFMMNZncVIgpB41prZdIudhROxlemv8RGTyWfbhSn+Dp1xqsKRW6kuU9KIM97G49Ruzmq+sIwW/TgSE5Uy8= drath@DESKTOP-91HBU1O"
			"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDmfY5w2m8MxWbr1b5Af821LtP9UCOjV7KtiSguld8juw7ApfIQHlhrUdCpE1XqU6x8guKjFBnH37o3THd9tV/S6lB8vPd9mUL6rIdex7gu4hjUGopQ0FZ7XObuYcSuk43Ro4IHfHMB0OaL3OC73ndyJExFohnpM+cOGka17G8Vam/tJnZRuFflT+M9JLYTcvn2hkGDmKGMoMtyLJBLIWBnAd3auTRfPHxPw9UQt6aDYbaC+mvms0tk5SGXdPWjff2QUTb9KxNuNOlywiok69P7OSEfw/2NV1bzbm2QiPBfEplTdyCgEqKU2Rydq9JR0zG552pt5Po/6ySI631aazrgZUMN1cba+kveiR+3ef72WqJHr2Mp4sEzTBIZrajd6fzX8lxiwZj3gPV+zvV4XB9eeDrecJVAWM4l4utS7i4/dvDXsAKaj19tx0CjsUX19RR2oqJSjHFy05r3W1sonWq6iCE3JGOh4Yc1HM09U/QJC9wtXRFT14oxMN3eL2x9hP8= drath@x220.lan"
		];
	};
	
	programs.bash.interactiveShellInit = "if [[ -d $HOME/.bashrc.d ]]; then source $HOME/.bashrc.d/*; fi";
	
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
		openssh = {
			enable = true;
			settings.PasswordAuthentication = false;
			extraConfig = "AllowUsers drath@192.168.1.*\nAllowUsers drath@100.*";
		};
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


			rclone-config-downloader = {
				enable = true;
				path = [ pkgs.curl pkgs.gzip ];
				serviceConfig.Type = "oneshot";
				unitConfig.ConditionPathExists = "!%S/rclone/rclone.conf";
				serviceConfig.RemainAfterExit = "yes";
				scriptArgs = "%S";
				script = ''
					mkdir -p $1/rclone
					curl -sSL 192.168.1.1:82/?q=rclone.conf | base64 -d | gzip -d > $1/rclone/rclone.conf
				'';
				description = "Download homedir files from google drive";
				wantedBy = [ "default.target" ]; # this is what actually makes it run on boot
			};


			backup-configs = {
				enable = true;
				path = [ pkgs.pigz pkgs.gnutar pkgs.rclone ];
				serviceConfig.Type = "oneshot";
				description = "Backup scripts and configs to google drive";
				script = ''
					cd ~; tar -cvf - configs | pigz | rclone rcat google:backup/$HOSTNAME/$HOSTNAME-configs.tar.gz
					cd ~; tar -cvf - docker-compose | pigz | rclone rcat google:backup/$HOSTNAME/$HOSTNAME-docker-compose.tar.gz
					cd ~; tar -cvf - --exclude=runme.sh *.sh *.yml .bashrc.d mc | pigz | rclone rcat google:backup/$HOSTNAME/$HOSTNAME-home-dir.tar.gz
				'';
			};
		};

		timers = {
			backup-configs = {
				enable = true;
				wantedBy = [ "timers.target" ];
				description = "Timer to backup scripts and configs to google drive";
				timerConfig = {
					OnCalendar = "*-*-* 0,6,12,18:00:00";
					Unit = "backup-configs.service";
				};
			};
		};
	};

	system = {
		stateVersion = "23.05";
		autoUpgrade = {
			enable = true;
			allowReboot = true;
			channel = "https://channels.nixos.org/nixos-23.05";
			rebootWindow = {
				lower = "01:00";
				upper = "05:00";
			};
		};
	};
}