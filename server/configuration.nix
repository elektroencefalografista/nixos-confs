# TODO all nitpicks:
# - autodetect kernel version for modules?, though nixos uses LTS kernel so its not a huge deal
# - bash prompt?

# REAL TODO
# - config downloader with restic? do we need one? could use autoloading restic config

{ config, pkgs, ... }:

let 
	cfg = {
		hostname = "server";
		username = "drath";
		linuxVer = "linux_6_6"; # needed for extra kernel modules
		docker = {
			confDir = "$HOME/configs";
			storageDir = "/mnt/docker";
		};
		zfs.arcSize = 20*1024;
		mem.swapSize = 2048;
		oneshotConfigDownloaderSource = "server";
		eppPreference = "power";
	};
in

{
	imports = [
		./hardware-configuration.nix
		./common.nix
		(fetchTarball "https://github.com/nix-community/nixos-vscode-server/tarball/master")
	];

	boot = {
		# blacklistedKernelModules = [ "k10temp" ];
		kernelPackages = pkgs.linuxKernel.packages.${cfg.linuxVer};
		extraModulePackages = with pkgs.linuxKernel.packages.${cfg.linuxVer}; [ it87 ];
		kernelModules = [
			"it87" 
			# "vfio_pci"
			# "vfio"
			# "vfio_iommu_type1"
        	# "vfio_virqfd"			
		];
		supportedFilesystems = [ "zfs" ];
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
			"zfs.zfs_txg_timeout=30" # write to drives every 30s
			"initcall_blacklist=acpi_cpufreq_init"
			"amd_pstate=active"
			"pcie_aspm=force"
			"amd_iommu=on"
			# "vfio-pci.ids=10de:1048,10de:0e08"
			# "video=vesafb:off,efifb:off"
		];
	};

	environment = {
		etc = {
			"sensors3.conf" = {
				mode = "0644";
				text = ''
					chip "it8655-isa-0290"
					ignore in0
					ignore in1
					ignore in2
					ignore in3
					ignore in4
					ignore in5
					ignore in6
					ignore temp1
					ignore temp2
					ignore temp3
					ignore temp4
					ignore temp5
					ignore temp6
					ignore intrusion0
				'';
			};
		};

		systemPackages = with pkgs; [
			vim
			restic
			wget
			ffmpeg
			# mergerfs
			curl
			pciutils
			screen
			zip
			reptyr
			lshw
			git
			nmap
			gnumake
			qemu
			qemu-utils
			lm_sensors
		];
		
		variables = {
			DOCKER_CONF_DIR = cfg.docker.confDir;
			DOCKER_STORAGE_DIR = cfg.docker.storageDir; # maybe we should make it a nix variable for other services i port from docker
			TZ = "$(ls -l /etc/localtime | rev | cut -d \"/\" -f1-2 | rev)";
			EDITOR = "nano";
			XZ_DEFAULTS = "-T0";
		};

		shellAliases = {
			yt = "docker run -i -e PGID=1000 -e PUID=1000 -v /mnt/anime/yt-dl:/downloads -v ${cfg.docker.storageDir}/cookies.txt:/cookies.txt -u 1000:1000 jauderho/yt-dlp --cookies /cookies.txt";
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
		tailscale.enable = true; # still need to join by hand but thats probably fine
		vscode-server.enable = true;
		zfs.autoScrub = {
			enable = true;
			interval = "weekly";
		};

		restic.backups = {
			promdb = {
				passwordFile = "/etc/restic/restic-pw";
				repositoryFile = "/etc/restic/repository";
				environmentFile = "/etc/restic/s3Credentials.env";
				paths = [ "${cfg.docker.storageDir}/promdb"	];
				pruneOpts = [
					"--keep-daily 7"
					"--keep-weekly 4"
					"--keep-monthly 12"
					"--keep-yearly 75"
					"--tag prometheus"
				];
				timerConfig = {
					OnCalendar = "*-*-* 1:00:00"; # daily at 1am, maybe its enough to back up weekly with db on zfs
					Persistent = "true";
					RandomizedDelaySec = 30 * 60;
				};
				extraBackupArgs = [ "--tag prometheus" ];
			};
		};

		# nfs = {
		# 	server = {
		# 		enable = true;
		# 		exports = ''
		# 			/mnt 192.168.1.0/24(ro,fsid=0,no_subtree_check) 100.0.0.0/8(ro,fsid=0,no_subtree_check)
		# 			/mnt/anime 192.168.1.0/24(rw,fsid=1,sync,no_subtree_check,crossmnt) 100.0.0.0/8(rw,fsid=1,sync,no_subtree_check,crossmnt)
		# 		'';
		# 	};
		# 	extraConfig = ''
		# 		[nfsd]
		# 		vers3=n
		# 	'';
		# };

		telegraf = {
			enable = true;
			extraConfig = {
				global_tags = {
					interval = "5s";
				};
				inputs = {
					mem = {};
					cpu = {};
					sensors = {
						# remove_numbers = false;
					};
					system = {};
					smart = {
						interval = "1m";
						attributes = true;
					};
					systemd_units = {};
					docker = {
						endpoint =  "unix:///run/docker.sock";
  						perdevice = false;
  						total = true;
  						total_include = [ "cpu" "blkio" "network" ];
					};
					net = {
						# interval = "5s";
  						interfaces = [ "enp*s[0-9]" ];
					};
					disk = {
						interval = "15s";
						ignore_fs = [ "tmpfs" "devtmpfs" "devfs" "iso9660" "overlay" "aufs" "squashfs" ];
					};
					diskio = {
						device_tags = [ "ID_MODEL" "ID_SERIAL_SHORT" "ID_PATH" "ID_ATA_ROTATION_RATE_RPM" ];
					};
					zfs = {
						interval = "15s";
						poolMetrics = true;
					};
				};

				outputs = {
					prometheus_client = {
						listen = ":9273";
						# ip_range = [ 
						# 	"192.168.1.0/24"
						# 	"127.0.0.0/24"
						# ];
						metric_version = 2;
					};
					mqtt = {
						servers = [ "192.168.1.1:1883" ];
						qos = 0;
						topic = "telegraf/{{ .Hostname }}/{{ .PluginName }}/{{.Tag \"path\" }}";
						client_id = "telefraf";
						# username = "telegraf";
						# password = "ukVDMfkJX7tjh/sR7Vl6";
						data_format = "json";
						# layout = "field";
						layout = "batch";
					};
				};
			};
		};

		# probably should move to common
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
			set-performance-policy = {
				serviceConfig = {
					User = pkgs.lib.mkForce "root";
					Group = pkgs.lib.mkForce "root";
				};
				script = ''
					for value in {0..15}; do echo ${cfg.eppPreference} > /sys/devices/system/cpu/cpufreq/policy''${value}/energy_performance_preference; done
				'';
			};
		};
	};

	system.stateVersion = "23.05";
	system.autoUpgrade.allowReboot = false;
	powerManagement = {
		cpuFreqGovernor = "powersave";
	};
}