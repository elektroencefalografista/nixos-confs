# TODO all nitpicks:
#	- autodetect kernel version for modules?, though nixos uses LTS kernel so its not a huge deal
# 	- bash prompt?

{ config, pkgs, ... }:

let 
	cfg = {
		hostname = "server";
		username = "drath";
		linuxVer = "linux_6_1"; # needed for extra kernel modules
		zfs.arcSize = 4096;
		mem.swapSize = 8196;
		oneshotConfigDownloaderSource = "server";
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
		extraModulePackages = with pkgs.linuxKernel.packages.${cfg.linuxVer}; [ zenpower it87 ];
		kernelModules = [ "zenpower" "it87" ];
		supportedFilesystems = [ "zfs" "btrfs" ];
		zfs.extraPools = [ "zpool" ];

		loader = {
			systemd-boot.enable = true;
			efi.canTouchEfiVariables = true;
		};

		kernel.sysctl = {
			"vm.swappiness" = 15;
		};

		kernelParams = [ 
			"zfs.zfs_arc_min=0"
			"zfs.zfs_arc_max=${toString (cfg.zfs.arcSize * 1048576)}" 
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
			wget
			htop
			neofetch
			mergerfs
			curl
			pciutils
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
	};


	networking = {
		hostName = cfg.hostname;
		hostId = "5c932f77"; # for zfs: importing a pool will fail if pool wasnt properly exported and the ID is different than the ID of the machine that the pool was last imported on
		networkmanager.enable = true;
		firewall.checkReversePath = "loose"; # suggested for tailscale
		firewall.enable = false; # yea no. gotta figure out what ports i need
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
					/mnt 192.168.1.0/24(ro,fsid=0,no_subtree_check)
					/mnt/anime 192.168.1.0/24(rw,fsid=1,sync,no_subtree_check,crossmnt)
				'';
			};
			extraConfig = ''
				[nfsd]
				vers3=n
			'';
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
						device_tags = [ "ID_MODEL" "ID_SERIAL_SHORT" "ID_PATH" ];
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
	};

	
	systemd = {
		services = {
			telegraf = { # hack to make smartctl work
				path = [ pkgs.lm_sensors pkgs.smartmontools pkgs.nvme-cli ];
				serviceConfig = {
					User = pkgs.lib.mkForce "root";
					Group = pkgs.lib.mkForce "root";
				};
			};

			backup-configs = {
				enable = true;
				path = [ pkgs.pigz pkgs.gnutar pkgs.rclone ];
				serviceConfig = {
					Type = "oneshot";
					User = cfg.username;
				};
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
				requires = [ "backup-configs.service" ]; # fuck you
				timerConfig = {
					OnCalendar = "*-*-* 0,6,12,18:00:00";
					Unit = "backup-configs.service";
				};
			};
		};

		user = {
			services = {
				oneshot-config-downloader = {
					enable = true;
					path = [ pkgs.pigz pkgs.gnutar pkgs.rclone ];
					after = [ "rclone-config-downloader.service" ];
					serviceConfig.Type = "oneshot";
					unitConfig.ConditionPathExists = "!%S/%N.stamp";
					serviceConfig.RemainAfterExit = "yes";
					scriptArgs = "%S %N ${cfg.oneshotConfigDownloaderSource}";
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
					description = "Download rclone config";
					wantedBy = [ "default.target" ]; # this is what actually makes it run on boot
				};
			};
		};
	};

	system.stateVersion = "23.05";
	powerManagement.cpuFreqGovernor = "conservative";
}
