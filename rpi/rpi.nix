# TODO figure out how to backup/provision basic settings for pihole
# TODO flask gcs downloader with nix insted of docker. time to learn flakes ig
# TODO gonna need rclone downloader. wont work on first boot when docker isnt setup, but it will work eventually


{ config, pkgs, ... }:

let 
	cfg = {
		hostname = "rpi";
		username = "drath";
		mem.swapSize = 512;
	};
in

{	
	imports = [
		./hardware-configuration.nix
		(builtins.fetchurl { url="https://raw.githubusercontent.com/elektroencefalografista/nixos-confs/main/common.nix"; })
	];

	boot =  {
		loader = {
			grub.enable = false;
			generic-extlinux-compatible.enable = true;
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
		# firewall.enable = false; # yea no
		firewall.allowedTCPPorts = [ 53 67 80 82 3000 ]; # port 81 still works?
		firewall.allowedUDPPorts = [ 53 67 547 ];
	};

	swapDevices = [{
		device = "/var/lib/swapfile";
		size = cfg.mem.swapSize;
	}];

	environment.systemPackages = with pkgs; [
		wget
		htop
		neofetch
		libraspberrypi
	];

	services = {
		tailscale.enable = true; # TODO remove eventually?

		grafana = {
			enable = true;
			provision = {
				enable = true;
				datasources.settings.datasources = [{
					name = "Server";
					type = "prometheus";
					url = "http://server.lan:9090";
				}];
				# dashboards.path = "/path"; #TODO?
			};
			settings = {
				server = {
					http_addr = "0.0.0.0";
					http_port = 3000;
					# domain = "grafana.drath.cc";
				};
				security = {
					admin_user = "drath";
					admin_email = "drathvader@wp.pl";
				};
			};

		};
	};

	systemd = {
		services = {
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
	};


	virtualisation.docker.enable = true;
	system.stateVersion = "23.05";
}
