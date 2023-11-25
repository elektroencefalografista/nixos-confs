# TODO all nitpicks:
# - autodetect kernel version for modules?, though nixos uses LTS kernel so its not a huge deal
# - bash prompt?

# REAL TODO
# - config downloader with restic? do we need one?

{ config, pkgs, ... }:

let 
	cfg = {
		hostname = "server";
		username = "drath";
		linuxVer = "linux_6_1"; # needed for extra kernel modules
		zfs.arcSize = 6144;
		mem.swapSize = 2048;
		oneshotConfigDownloaderSource = "server";
		net.interface_name = "enp6s0"; # breaks on different hardware ugh. predictable names? maybe just dhcp after all
	};
in

{
	imports = [
		./hardware-configuration.nix
		./common.nix
		(fetchTarball "https://github.com/nix-community/nixos-vscode-server/tarball/master")
	];

	boot = {
		blacklistedKernelModules = [ "k10temp" ];
		extraModulePackages = with pkgs.linuxKernel.packages.${cfg.linuxVer}; [ zenpower ];
		kernelModules = [ "zenpower" ];
		supportedFilesystems = [ "zfs" "btrfs" ];
		zfs.extraPools = [ "zpool" ];

		loader = {
			systemd-boot.enable = true;
			efi.canTouchEfiVariables = true;
		};

		kernel.sysctl = {
			"vm.swappiness" = 5;
		};

		kernelParams = [ 
			"zfs.zfs_arc_min=0"
			"zfs.zfs_arc_max=${toString (cfg.zfs.arcSize * 1048576)}"
			"initcall_blacklist=acpi_cpufreq_init"
			"amd_pstate=passive"
		];
	};

	environment = {
		etc = {
			"rclone/rclone.conf" = {
				mode = "0644";
				source = "/home/${cfg.username}/.config/rclone/rclone.conf";
			};
		};

		systemPackages = with pkgs; [
			vim
			restic
			wget
			ffmpeg
			mergerfs
			curl
			pciutils
			screen
			zip
			lshw
			git
			nmap
			gnumake
			lm_sensors
		];
		
		variables = {
			DOCKER_CONF_DIR = "$HOME/configs";
			DOCKER_STORAGE_DIR = "/mnt/zpool/.docker-storage"; # maybe we should make it a nix variable for other services i port from docker
			TZ = "$(ls -l /etc/localtime | rev | cut -d \"/\" -f1-2 | rev)";
			EDITOR = "nano";
			XZ_DEFAULTS = "-T0";
		};

		shellAliases = {
			yt = "docker run -i -e PGID=1000 -e PUID=1000 -v /mnt/anime/yt-dl:/downloads -v /mnt/zpool/.docker-storage/cookies.txt:/cookies.txt -u 1000:1000 jauderho/yt-dlp --cookies /cookies.txt";
			mk_filelist = "sudo find /mnt/anime -name '*' | sort | gzip -9 > filelist.txt.gz";
		};

		shellInit = ''
			function chomik() {
					docker run -it --rm \
					-v "/mnt/anime/!-Animy":/anime:ro \
					-v "/mnt/share/upload":/upload \
					chomikuj \
					$@.py
			}
		'';
	};


	networking = {
		hostName = cfg.hostname;
		hostId = "5c932f77"; # for zfs: importing a pool will fail if pool wasnt properly exported and the ID is different than the ID of the machine that the pool was last imported on
		networkmanager.enable = true;
		firewall.checkReversePath = "loose"; # suggested for tailscale
		firewall.enable = false; # yea no. gotta figure out what ports i need
		interfaces.${cfg.net.interface_name}.ipv4.addresses = [{ 
			address = "192.168.1.200";
			prefixLength = 24;
		}];
		defaultGateway = "192.168.1.254";
		nameservers = [ "192.168.1.1" ];
	};


	fileSystems = {
		"/mnt/mfs_share" = {
			device = "/dev/disk/by-uuid/cdb15f8d-7a83-4b33-aaf7-e4147261900a";
			fsType = "btrfs";
			options = [ 
				"relatime" 
				"nofail"
				"defaults"
				"x-systemd.mount-timeout=15" ];
		};

		"/mnt/mfs_anime" = {
			device = "/dev/disk/by-uuid/f4ecfce7-0ff2-4f1f-9709-de874618fe58";
			fsType = "btrfs";
			options = [ 
				"relatime" 
				"nofail"
				"defaults"
				"x-systemd.mount-timeout=15" ];
		};

		"/mnt/mfs_purple" = {
			device = "/dev/disk/by-uuid/557885a9-7107-43d2-bab8-109a36b351af";
			fsType = "ext4";
			options = [ 
				"relatime" 
				"nofail"
				"defaults"
				"x-systemd.mount-timeout=15" ];
		};

		"/mnt/anime" = {
			device = "/mnt/mfs_*:/mnt/zpool";
			fsType = "fuse.mergerfs";
			options = [ 
				"defaults" 
				"nonempty"
				"allow_other"
				"use_ino"
				"category.create=msplfs"
				"dropcacheonclose=true"
				"minfreespace=10G"
				"fsname=mfs_pool"
				"nofail" ];
			depends = [ "/mnt/zpool" "/mnt/mfs_anime" "/mnt/mfs_share" "/mnt/mfs_purple"];
			noCheck = true;
		};
	};


	swapDevices = [ {
   		device = "/var/lib/swapfile";
    	size = cfg.mem.swapSize;
 	} ];


	virtualisation.docker = {
		enable = true;
		listenOptions = [ "/run/docker.sock" "0.0.0.0:2375"  ];
	};

	services = {
		getty.autologinUser = cfg.username;
		timesyncd.enable = true;
		tailscale.enable = true; # still need to join by hand but thats probably fine
		vscode-server.enable = true;
		zfs.autoScrub.enable = true;

		nfs = {
			server = {
				enable = true;
				exports = ''
					/mnt 192.168.1.0/24(ro,fsid=0,no_subtree_check) 100.0.0.0/8(ro,fsid=0,no_subtree_check)
					/mnt/anime 192.168.1.0/24(rw,fsid=1,sync,no_subtree_check,crossmnt) 100.0.0.0/8(rw,fsid=1,sync,no_subtree_check,crossmnt)
				'';
			};
			extraConfig = ''
				[nfsd]
				vers3=n
			'';
		};

		samba-wsdd.enable = true;
		samba = {
			enable = true;
			openFirewall = true;
			securityType = "user";
			extraConfig = ''
				server min protocol = SMB3
				workgroup = WORKGROUP
				server string = server
				netbios name = server
				use sendfile = yes
				hosts allow = 192.168.1. 100.
				hosts deny = 0.0.0.0/0
				guest account = nobody
				map to guest = bad user
			'';
			shares = {
				anime = {
					path = "/mnt/anime";
					"valid users" = "drath";
					"guest ok" = "no";
					"read only" = "no";
					"browseable" = "yes";
					"create mask" = "0644";
   					"directory mask" = "0755";
	  				"force user" = "drath";
	  				# "force group" = "drath";
				};
				movies = {
					path = "/mnt/anime/Jellyfin";
					"guest ok" = "yes";
					"read only" = "yes";
					"browseable" = "yes";
				};
			};
		};


		telegraf = {
			enable = true;
			extraConfig = {
				inputs = {
					mem = {};
					cpu = {};
					sensors = {};
					system = {};
					smart = {
						attributes = true;
					};
					docker = {
						endpoint =  "unix:///run/docker.sock";
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
						device_tags = [ "ID_MODEL" "ID_SERIAL_SHORT" "ID_PATH" "ID_ATA_ROTATION_RATE_RPM" ];
					};
					zfs = {
						poolMetrics = true;
					};
				};

				outputs.prometheus_client = {
					listen = ":9273";
					ip_range = [ "192.168.1.0/24" ];
					metric_version = 2;
				};
			};
		};

		# probably should move to common
		restic.backups = {
			confs = {
				passwordFile = "/etc/restic/restic-pw";
				repositoryFile = "/etc/restic/repository";
				environmentFile = "/etc/restic/s3Credentials.env";
				paths = [ 
					"/home/${cfg.username}/configs"
					"/home/${cfg.username}/build"
					"/home/${cfg.username}/scripts"
					"/home/${cfg.username}/mc"
					"/home/${cfg.username}/docker-compose.yml"
				];
				pruneOpts = [
					"--keep-daily 4"
					"--keep-weekly 5"
					"--keep-monthly 12"
					"--keep-yearly 75"
				];
				timerConfig = {
					OnCalendar = "*-*-* 0,6,12,18:00:00";
					Persistent = "true";
				};
			};
		};
	};

	
	systemd = {
		services = {
			# hack to make smartctl work
			telegraf = {
				path = [ pkgs.lm_sensors pkgs.smartmontools pkgs.nvme-cli ];
				serviceConfig = {
					User = pkgs.lib.mkForce "root";
					Group = pkgs.lib.mkForce "root";
				};
			};
		};
	};

	system.stateVersion = "23.05";
	system.autoUpgrade.allowReboot = true; # gonna risk it
	powerManagement.cpuFreqGovernor = "conservative";
}