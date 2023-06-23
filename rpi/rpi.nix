# TODO add actual firewall rules. we need:
#		- port 80 for pihole
#		- port 82 for rclone thing
#		- ports 3000 for grafana and 9090 for prometheus datasource
# TODO oh wait, cant have common rclone downloader for pi becuase it downloads from pi. ig no google backups for pi
# but also i only really need to backup pihole settings so eh
# maybe we could do that with home manager?
# TODO flask gcs downloader with nix insted of docker. time to learn flakes ig


{ config, pkgs, ... }:

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
		hostName = "rpi";
		firewall.enable = false; # yea no
	};

	swapDevices = [{
		device = "/var/lib/swap.img";
		size = 1*1024; # 1GB
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

	virtualisation.docker.enable = true;
	system.stateVersion = "23.05";
}
