# TODO figure out how to backup/provision basic settings for pihole?
# TODO http with flask instead of docker
# TODO backing up prometheus database somehow

{ config, pkgs, ... }:

let 
	cfg = {
		hostname = "atom";
		username = "drath";
		mem.swapSize = 256;
	};
in

{	
	
	imports = [
		./hardware-configuration.nix
		(builtins.fetchurl { url="https://raw.githubusercontent.com/elektroencefalografista/nixos-confs/main/common.nix"; })
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
		nameservers = [ "127.0.0.1" "1.1.1.1" ];
		hostName = cfg.hostname;
		firewall.allowedTCPPorts = [ 53 67 80 82 9090 9443 ]; # port 81 still works?
		firewall.allowedUDPPorts = [ 53 67 547 ];
	};

	swapDevices = [{
		device = "/var/lib/swapfile";
		size = cfg.mem.swapSize;
	}];

	environment = {
		etc = {
			"cloudflared_tunnel.json" = {
				mode = "0644";
				source = "/home/${cfg.username}/configs/cloudflared/29bb852d-8363-4728-8acc-14fe66f5b8d8.json";
			};

			"rclone/rclone.conf" = {
				mode = "0644";
				source = "/home/${cfg.username}/configs/rclone.conf";
			};
		};

		systemPackages = with pkgs; [
			htop
			neofetch
			git
			rsync
		];
	};

	services = {
		tailscale.enable = true; # TODO remove eventually?

		cloudflared = {
			enable = true;
			tunnels = {
				"29bb852d-8363-4728-8acc-14fe66f5b8d8" = {
					credentialsFile = "/etc/cloudflared_tunnel.json";
					default = "http_status:404";
					ingress = {
						"grafana.drath.cc" = "http://localhost:3000";
						# "portainer.drath.cc" = "http://localhost:9433"; # idk about making this one public
						"precious.drath.cc" = "http://localhost:1111";
					};
				};
			};
		};

		grafana = {
			enable = true;
			provision = {
				enable = true;
				datasources.settings.datasources = [{
					name = "Server";
					type = "prometheus";
					url = "http://localhost:9090";
				}];
				# dashboards.path = "/path"; # maybe we could have a default, read-only dashboard? TODO?
			};
			settings = {
				server = {
					http_addr = "0.0.0.0";
					http_port = 3000;
				};
				security = {
					admin_user = "drath";
					admin_email = "drathvader@wp.pl";
				};
			};

		};

		prometheus = {
			enable = true;
			retentionTime = "365d";
			globalConfig = {
				scrape_interval = "15s";
				evaluation_interval = "15s";
			};
			scrapeConfigs = [{
				job_name = "telegraf";
				scrape_interval = "15s";
				static_configs = [{
					targets = [ "192.168.1.200:9273" ];
				}];
			}];
			extraFlags = [
				"--storage.tsdb.retention.size=32GB"
			];
		};
	};

	systemd = {
		services = {
			backup-configs = {
				enable = true;
				path = with pkgs; [ pigz gnutar rclone ];
				serviceConfig = {
					Type = "oneshot";
				};
				description = "Backup scripts and configs to google drive";
				script = ''
					cd /home/${cfg.username}; tar -cvf - configs | pigz | rclone --config=/etc/rclone/rclone.conf rcat google:backup/$HOSTNAME/$HOSTNAME-configs.tar.gz
					cd /home/${cfg.username}; tar -cvf - docker-compose | pigz | rclone --config=/etc/rclone/rclone.conf rcat google:backup/$HOSTNAME/$HOSTNAME-docker-compose.tar.gz
					cd /home/${cfg.username}; tar -cvf - --exclude=runme.sh *.sh *.yml .bashrc.d mc | pigz | rclone --config=/etc/rclone/rclone.conf rcat google:backup/$HOSTNAME/$HOSTNAME-home-dir.tar.gz
				'';
			};
		};

		timers = {
			backup-configs = {
				enable = true;
				wantedBy = [ "timers.target" ];
				description = "Timer to backup scripts and configs to google drive";
				requires = [ "backup-configs.service" ];
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
