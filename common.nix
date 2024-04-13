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

	users = {
		users."${cfg.username}" = {
			isNormalUser = true;
			description = cfg.username;
			extraGroups = [ "networkmanager" "wheel" "docker" "${cfg.username}" ];
			openssh.authorizedKeys.keys = [
				"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID23uJGojUy2EHk8glneYEVTR5RyzM8q9YZ5EPltptph drath@atom"
				"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGYExFpR+Cy7St1gFkR9Ccof9uHQ8HPhlHJOmFlDypn4 drath@GAMEMACHINE"
				"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJEPAwP+duI7itVoHWTQEzAk/Jx6+DmTMoPTU0BBVWO drath@X390"
				"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICdwLzGw3GUy+MT2lFr8dosPGpLbKZlWELOGb72lrPUU drath@s23"
				"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICCY8I34dzrx51d5DLqjmjoz6XM312ve9g++cYjhnBAa drath@nexus9"
			];
		};
		groups."${cfg.username}" = {
			gid = 1000;
		};
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