# common config options that genereally dont change often
# TODO figure out how to import vars from this
# TODO rewrite backup service with restic instead of rclone

let 
	cfg = {
		username = "drath";
		backup = {
			backend = "b2:drath-backup";
		};
	};
in


{ config, pkgs,  ... }:

{
	imports = [
		./secrets.nix
	];

	boot.tmp.cleanOnBoot = true;
	i18n.defaultLocale = "pl_PL.UTF-8"; # need to be set explicitly
	time.timeZone = "Europe/Warsaw";
	programs.bash.shellInit = "if [[ -d $HOME/.bashrc.d ]]; then source $HOME/.bashrc.d/*; fi\nHISTCONTROL=ignoredups:erasedups";
	security.sudo = {
		enable = true;
		wheelNeedsPassword = false; # appearently thats outdated
	};

	users.users."${cfg.username}" = {
		isNormalUser = true;
		description = cfg.username;
		extraGroups = [ "networkmanager" "wheel" "docker" ];
		openssh.authorizedKeys.keys = [
			"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDp8J8KX2i3hCr8s7GJ+Yq2sY1NI252pD3FGwhiSCOATs3xckUqLXSMEJWS+jFLkq6S+oXAVNKkCmUa1jVKJg0slP4Fy/hH50QjsasJglWNZJgbls4fwcNFoBmb2S/7GKPOQFGnVtuKLtnnbxPGUYzLTVbJZORXdV4jc0ChyetdQdvKIgpPYqWKkYkpRhbQ+DnEXgQ7zi20vpDzuAWbBzrqt4aQrIq0KhaWSAJvSKUF88qqVkmp0e7yD9Rf3XwmBP/AQDTBlVzhX/sgEMmO/orvYBFHQ6etDs25L/TuPIczTaKEochIat+0qzW/ZuOHjiADsYaARNI+zwefwlR2H7UnwwZC1FY6PXRaPjribIlI8KVnRVby7aJMKlzXH235WjqdUkYWG2L9CM2cGFnEoGesz4gwmC4r6a53kRarVICezrwnCtLDHLiEzfT7PJ07jujPCsIZ9iKoZt98irlYSw3nXcxV6UYCBnQzJ2e/RRmIpR0Bv7lexaf7AF4FZuktkFk= drath@desktop"
			"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSbAgVbfQZJFrI1i3NnCPHJRAfB4b/f7/pjE3T/7RvaLUH0vd7PR1PtvHkMl6vGJULVBA7coXjmlb1mJ/NPCsjdJg71VxJD2Wjm0lFeyPnm41aCHn3Pi7vbyib9i8xaZtflxkufpjrAZ/PeKNxMivIdFySH3aKelkvNYoTjGj4+oPhzpRTu1TJinAtqJACSvY4z0zNbADW1QqFabuRet8oCAUnWeMKTUrX1h+TSNOCo7BAM7EMaWl7+Wuahc4uAWuAhTcPmxJMW50G4WWxexdyy8sSUnrbH+ohgwkS/ZnePelDApfbIPkBDW0vKoVXKjTSDgm9awEHscVqF6OZv+lC8tZ10WjBHIC+tLLEAHTkSSIJM3XBsl9ohEmPmlbcz7tWaM5x12XLDMVgzT9cus/ArMmrpY091FRGZWr6GQH5YTfzPFMMNZncVIgpB41prZdIudhROxlemv8RGTyWfbhSn+Dp1xqsKRW6kuU9KIM97G49Ruzmq+sIwW/TgSE5Uy8= drath@thinkpad"
			"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDmfY5w2m8MxWbr1b5Af821LtP9UCOjV7KtiSguld8juw7ApfIQHlhrUdCpE1XqU6x8guKjFBnH37o3THd9tV/S6lB8vPd9mUL6rIdex7gu4hjUGopQ0FZ7XObuYcSuk43Ro4IHfHMB0OaL3OC73ndyJExFohnpM+cOGka17G8Vam/tJnZRuFflT+M9JLYTcvn2hkGDmKGMoMtyLJBLIWBnAd3auTRfPHxPw9UQt6aDYbaC+mvms0tk5SGXdPWjff2QUTb9KxNuNOlywiok69P7OSEfw/2NV1bzbm2QiPBfEplTdyCgEqKU2Rydq9JR0zG552pt5Po/6ySI631aazrgZUMN1cba+kveiR+3ef72WqJHr2Mp4sEzTBIZrajd6fzX8lxiwZj3gPV+zvV4XB9eeDrecJVAWM4l4utS7i4/dvDXsAKaj19tx0CjsUX19RR2oqJSjHFy05r3W1sonWq6iCE3JGOh4Yc1HM09U/QJC9wtXRFT14oxMN3eL2x9hP8= drath@x220"
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGYExFpR+Cy7St1gFkR9Ccof9uHQ8HPhlHJOmFlDypn4 drath@GAMEMACHINE"
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJEPAwP+duI7itVoHWTQEzAk/Jx6+DmTMoPTU0BBVWO drath@X390"
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICdwLzGw3GUy+MT2lFr8dosPGpLbKZlWELOGb72lrPUU drath@s23"
			"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICCY8I34dzrx51d5DLqjmjoz6XM312ve9g++cYjhnBAa drath@nexus9"
		];
	};

	environment = {
		systemPackages = with pkgs; [
			htop
			neofetch
		];

		shellAliases = {
			ll = "ls -al";
			lh = "ls -alh";
		};

		shellInit = ''
			function dc() {
				NAME="$1"
				shift
				if [[ "''${NAME}" == "-a" ]]; then
						for FILE in *.yml; do
								docker compose -f "''${FILE}" -p $(basename "''${FILE}" .yml) $@
						done
				else
						docker compose -f ''${NAME} -p $(basename ''${NAME} .yml) $@
				fi
			}

			function duh() {
					du $1 -d 1 -h | sort -hr | tail -n +2
			}
		'';
	};


	nix = {
		settings = {
			auto-optimise-store = true;
		};
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
		openssh = {
			enable = true;
			settings = {
				PermitRootLogin = "no";
				PasswordAuthentication = false;
			};
			extraConfig = ''
				AllowUsers ${cfg.username}@192.168.1.*
				AllowUsers ${cfg.username}@100.*
			'';
		};

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
					"--keep-daily 7"
					"--keep-weekly 4"
					"--keep-monthly 12"
					"--keep-yearly 75"
					"--tag configs"
				];
				timerConfig = {
					OnCalendar = "*-*-* 0,6,12,18:00:00";
					Persistent = "true";
					RandomizedDelaySec = 15 * 60;
				};
				extraBackupArgs = [ "--tag configs" ];
			};
		};

		timesyncd.enable = true;
	};

	system.autoUpgrade = {
		enable = true;
		# allowReboot = true;
		channel = "https://channels.nixos.org/nixos-23.11";
		rebootWindow = {
			lower = "01:00";
			upper = "05:00";
		};
	};
	
	# fixes a systemd bug, nixos-rebuild fails on nm-wait-online
	systemd.services.NetworkManager-wait-online.enable = pkgs.lib.mkForce false;
	systemd.services.systemd-networkd-wait-online.enable = pkgs.lib.mkForce false;
}