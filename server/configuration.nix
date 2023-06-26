# TODO: we could PROBABLY move some of the critical services away from docker and into this: 
# 		- cloudflared but i like it on a separate network with all the shit thats running off of it
#		- ngrok maybe? no, needs python script to update cloudflare dns
#		- telegraf + prometheus, or at least telegraf. needs access to everything anyway
#		- maybe samba? nfs perchance? i like em in docker tho
#		- portainer??? perchance

# HOW TF WAS KERNEL MODULES THIS EASY. this alone is enough of a reason to switch away from ubuntu 
# TODO autodetect kernel version for modules?, though nixos uses LTS kernel so its not a huge deal

{ config, pkgs, ... }:

let 
	cfg = {
		linuxVer = "linux_6_1";
	};
in

{
	imports = [
		./hardware-configuration.nix
		(fetchTarball "https://github.com/nix-community/nixos-vscode-server/tarball/master")
		(builtins.fetchurl { url="https://raw.githubusercontent.com/elektroencefalografista/nixos-confs/main/common.nix"; })
	];

	########### BASICS and NETWORKING ###########


	boot = {
		extraModulePackages = with pkgs.linuxKernel.packages.${cfg.linuxVer}; [ zenpower it87 ];
		loader = {
			systemd-boot.enable = true;
			efi.canTouchEfiVariables = true;
		};
		blacklistedKernelModules = [ "k10temp" ];
		kernelModules = [ "nfs" "nfsd" "tun" "zenpower" "it87" ]; # not sure if i really need tun
		supportedFilesystems = [ "zfs" "btrfs" ]; # zfs not strictly needed? need 2 test
		# zfs.extraPools = [ "zpool" ];
		kernelParams = [ "zfs.zfs_arc_min=0" "zfs.zfs_arc_max=1073741824" ]; # 1GB
		tmp.cleanOnBoot = true;
	};

	networking = {
		hostName = "nox-test"; # Define your hostname.
		hostId = "5c932f77"; # for zfs, needs to be random TODO test importing if pool created with a diff id
		networkmanager.enable = true;
		firewall.checkReversePath = "loose"; # suggested for tailscale
		firewall.enable = false; # yea no
	};



	########### USERS, ENV VARS and SSH KEYS ###########
	
	environment.variables = {
		DOCKER_CONF_DIR = "$HOME/configs";
		DOCKER_STORAGE_DIR = "/mnt/zpool/.docker-storage"; # maybe we should make it a nix variable for other services i port from docker
		TZ = "$(ls -l /etc/localtime | rev | cut -d \"/\" -f1-2 | rev)";
		EDITOR = "nano";
		XZ_DEFAULTS = "-T0";
		MAIN_NET_IFACE = "$(ip link | grep -Eo \"enp[1-9]s0\")"; # am i even using this anymore?
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
		# rclone # dont REALLY need it? since its defined in systemd pkgs anyway
		neofetch
		mergerfs
		lm_sensors
	];

	services = {
		# getty.autologinUser = "drath";
		timesyncd.enable = true;
		tailscale.enable = true; # still need to join by hand but thats probably fine
		vscode-server.enable = true;
		zfs.autoScrub.enable = true;

		telegraf = {
			enable = true;
			extraConfig = {
				inputs = {
					mem = {};
					cpu = {};
					smart = {
						path_smartctl = "${pkgs.smartmontools}/bin/smartctl";
						path_nvme = "${pkgs.nvme-cli}/bin/nvme";
					};
					docker = {
						endpoint =  "unix://run/docker.sock";
  						perdevice = false;
  						total = true;
  						total_include = [ "cpu" "blkio" "network" ];
					};
					net = {
						interval = "5s";
  						interfaces = [ "enp*s[0-9]" ];
					};
					disk = {
						ignore_fs = [ "tmpfs" "devtmpfs" "devfs" "iso9660" "overlay" "aufs" "squashfs" ];
					};
					diskio = {
						device_tags = [ "ID_MODEL" "ID_SCSI_SERIAL" "ID_PATH" ];
					};
					zfs = {
						poolMetrics = true;
					};
				};

				outputs.prometheus_client = {
					listen = ":9273";
					metric_version = 2;
				};
			};
		};
	};


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
				enable = true; # maybe it would be better to explicitly include systemd.user.timers.backup-configs.enable = true; in each host
				wantedBy = [ "timers.target" ];
				description = "Timer to backup scripts and configs to google drive";
				timerConfig = {
					OnCalendar = "*-*-* 0,6,12,18:00:00";
					Unit = "backup-configs.service";
				};
			};
		};
	};

	system.stateVersion = "23.05";


	##### TESTING FLAKES BELOW
	nix.settings.experimental-features = [ "nix-command" "flakes" ];
}