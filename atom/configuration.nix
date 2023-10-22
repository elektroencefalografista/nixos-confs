# TODO figure out how to backup/provision basic settings for pihole?
# TODO http with flask instead of docker

{ config, pkgs, ... }:

let 
	cfg = {
		hostname = "atom";
		username = "drath";
		mem.swapSize = 256;
		backup = {
			backend = "b2:drath-backup";
		};
	};
in

{	
	
	imports = [
		./hardware-configuration.nix
		./common.nix
	];

	boot = {
		loader = {
			systemd-boot.enable = true;
			efi.canTouchEfiVariables = true;
		};
	};

	networking = {
		networkmanager.enable = true;
		interfaces.eth0.ipv4.addresses = [{
			address = "192.168.1.1";
			prefixLength = 24;
		}];
		defaultGateway = "192.168.1.254";
		nameservers = [ "127.0.0.1" ];
		hostName = cfg.hostname;
		firewall.enable = false;
		firewall.allowedTCPPorts = [ 53 67 80 82 8123 6053 9090 9443 ]; # port 81 still works?
		firewall.allowedUDPPorts = [ 53 67 547 ];
	};

	swapDevices = [{
		device = "/var/lib/swapfile";
		size = cfg.mem.swapSize;
	}];

	environment = {
		etc = {
			"rclone/rclone.conf" = {
				mode = "0644";
				source = "/home/${cfg.username}/configs/rclone.conf";
			};
		};

		systemPackages = with pkgs; [
			lm_sensors
		];
	};

	services.tailscale.enable = true; # TODO remove eventually?

	systemd = {
		services = {
			backup-prometheus-db = {
				enable = true;
				path = with pkgs; [ gnutar rclone pigz ];
				serviceConfig = {
					User = cfg.username;
					Type = "oneshot";
				};
				description = "Backup prometheus database to the cloud";
				script = ''
					tar -C /home/${cfg.username} -cf - promdb | pigz | rclone --config=/etc/rclone/rclone.conf rcat ${cfg.backup.backend}/$HOSTNAME/prometheus_db.tar.gz
				'';
			};
		};

		timers = {
			backup-prometheus-db  = {
				enable = true;
				wantedBy = [ "timers.target" ];
				description = "Timer to backup prometheus database to the cloud";
				requires = [ "backup-prometheus-db.service" ];
				timerConfig = {
					OnCalendar = "daily";
					Unit = "backup-prometheus-db.service";
				};
			};
		};
	};

	virtualisation.docker.enable = true;
	system.autoUpgrade.allowReboot = true; # gonna risk it
	powerManagement.cpuFreqGovernor = "conservative";
	system.stateVersion = "23.05";
}
