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
		systemPackages = with pkgs; [
			vim
			restic
			wget
			ffmpeg
			curl
			pciutils
			screen
			zip
			reptyr
			lshw
			git
			nmap
			gnumake
			lm_sensors
			python311Packages.requests
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

	virtualisation.libvirtd = {
		enable = true;
		qemu = {
			package = pkgs.qemu_kvm;
			runAsRoot = true;
			swtpm.enable = true;
			ovmf = {
				enable = true;
				# packages = [(pkgs.unstable.OVMF.override {
				# 	secureBoot = true;
				# 	tpmSupport = true;
				# }).fd];
			};
		};
	};

	services = {
		getty.autologinUser = cfg.username;
		tailscale.enable = true; # still need to join by hand but thats probably fine
		vscode-server.enable = true;
		zfs.autoScrub = {
			enable = true;
			interval = "weekly";
		};

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
						ip_range = [ 
							"192.168.1.0/24"
							"127.0.0.0/24"
						];
						metric_version = 2;
					};
					mqtt = {
						servers = [ "192.168.1.253:1883" ];
						qos = 0;
						topic = "telegraf/{{ .Hostname }}/{{ .PluginName }}";
						client_id = "telefraf";
						data_format = "json";
						layout = "batch";
					};
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

	powerManagement.cpuFreqGovernor = "powersave";
	system.stateVersion = "23.05";
	system.autoUpgrade = {
		allowReboot = false;
		enable = true;
	};
	
}