{ config, pkgs, ... }:

{
	
	imports = [
		./hardware-configuration.nix
	];


	boot =  {
		loader = {
			grub.enable = false;
			generic-extlinux-compatible.enable = true;
		};
	};


	time.timeZone = "Europe/Warsaw";
	i18n.defaultLocale = "en_US.UTF-8";
	security.sudo.wheelNeedsPassword = false;


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
  

	users.users.drath = {
		isNormalUser = true;
		extraGroups = [ "networkmanager" "wheel" "docker" ];
		hashedPassword = "$y$j9T$bnjLbA/0fVbi7aAbrAPbS/$LjSoS.ipo.ceLyJA0t/E1ZgAj68cNhloUC0hVBBMdU5";
		openssh.authorizedKeys.keys = [
			"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSbAgVbfQZJFrI1i3NnCPHJRAfB4b/f7/pjE3T/7RvaLUH0vd7PR1PtvHkMl6vGJULVBA7coXjmlb1mJ/NPCsjdJg71VxJD2Wjm0lFeyPnm41aCHn3Pi7vbyib9i8xaZtflxkufpjrAZ/PeKNxMivIdFySH3aKelkvNYoTjGj4+oPhzpRTu1TJinAtqJACSvY4z0zNbADW1QqFabuRet8oCAUnWeMKTUrX1h+TSNOCo7BAM7EMaWl7+Wuahc4uAWuAhTcPmxJMW50G4WWxexdyy8sSUnrbH+ohgwkS/ZnePelDApfbIPkBDW0vKoVXKjTSDgm9awEHscVqF6OZv+lC8tZ10WjBHIC+tLLEAHTkSSIJM3XBsl9ohEmPmlbcz7tWaM5x12XLDMVgzT9cus/ArMmrpY091FRGZWr6GQH5YTfzPFMMNZncVIgpB41prZdIudhROxlemv8RGTyWfbhSn+Dp1xqsKRW6kuU9KIM97G49Ruzmq+sIwW/TgSE5Uy8= drath@DESKTOP-91HBU1O"
			"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDmfY5w2m8MxWbr1b5Af821LtP9UCOjV7KtiSguld8juw7ApfIQHlhrUdCpE1XqU6x8guKjFBnH37o3THd9tV/S6lB8vPd9mUL6rIdex7gu4hjUGopQ0FZ7XObuYcSuk43Ro4IHfHMB0OaL3OC73ndyJExFohnpM+cOGka17G8Vam/tJnZRuFflT+M9JLYTcvn2hkGDmKGMoMtyLJBLIWBnAd3auTRfPHxPw9UQt6aDYbaC+mvms0tk5SGXdPWjff2QUTb9KxNuNOlywiok69P7OSEfw/2NV1bzbm2QiPBfEplTdyCgEqKU2Rydq9JR0zG552pt5Po/6ySI631aazrgZUMN1cba+kveiR+3ef72WqJHr2Mp4sEzTBIZrajd6fzX8lxiwZj3gPV+zvV4XB9eeDrecJVAWM4l4utS7i4/dvDXsAKaj19tx0CjsUX19RR2oqJSjHFy05r3W1sonWq6iCE3JGOh4Yc1HM09U/QJC9wtXRFT14oxMN3eL2x9hP8= drath@x220.lan"
		];
	};


	environment.systemPackages = with pkgs; [
		wget
		htop
		neofetch
		libraspberrypi
	];


	nix = {
		settings.auto-optimise-store = true;
		gc = {
			automatic = true;
			dates = "weekly";
			options = "--delete-older-than 30d";
		};
		extraOptions = ''
			min-free = ${toString (100 * 1024 * 1024)}
			max-free = ${toString (1024 * 1024 * 1024)}
		'';
	};


	services = {

		tailscale.enable = true;

		openssh = {
			enable = true;
			settings.PasswordAuthentication = false;
		};


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
					domain = "grafana.drath.cc";
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
