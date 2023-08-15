{ config, pkgs, ... }:

{
	imports = [
		./hardware-configuration.nix
	];

	boot = {
		supportedFilesystems = [ "ntfs" ];
		tmp.cleanOnBoot = true;
# 		plymouth = {
# 			enable = true;
# 			theme = "breeze";
# 		};
# 		kernelParams = [ "quiet" ];

		loader = {
			systemd-boot.enable = true;
			efi.canTouchEfiVariables = true;
		};

		initrd = {
# 			systemd.enable = true;
			secrets = {
				"/crypto_keyfile.bin" = null;
			};
		};
	};

	networking = {
		hostName = "t530";
		networkmanager.enable = true;
	};


	i18n = {
		defaultLocale = "pl_PL.UTF-8";
		extraLocaleSettings = {
			LC_ADDRESS = "pl_PL.UTF-8";
			LC_IDENTIFICATION = "pl_PL.UTF-8";
			LC_MEASUREMENT = "pl_PL.UTF-8";
			LC_MONETARY = "pl_PL.UTF-8";
			LC_NAME = "pl_PL.UTF-8";
			LC_NUMERIC = "pl_PL.UTF-8";
			LC_PAPER = "pl_PL.UTF-8";
			LC_TELEPHONE = "pl_PL.UTF-8";
			LC_TIME = "pl_PL.UTF-8";
		};
	};


	services = {
		timesyncd.enable = true;
		tailscale.enable = true;
		fprintd.enable = true;
		acpid.enable = true;
# 		flatpak.enable = true; # no way to set up flathub and install flatpaks declaratively
		printing.enable = true;
		colord.enable = true;
		
		xserver = {
			enable = true;
			dpi = 120;
			libinput.enable = true;
			layout = "pl";
			desktopManager.plasma5.enable = true;
			displayManager = {
				sddm.enable = true;
				autoLogin = {
					enable = true;
					user = "drath";
				};
			};
		};

		pipewire = {
			enable = true;
			alsa.enable = true;
			alsa.support32Bit = true;
			pulse.enable = true;
		};
	};

	swapDevices = [{
		device = "/var/lib/swapfile";
		size = 4096;
	}];

	security = {
		rtkit.enable = true;
		sudo.wheelNeedsPassword = false;
	};

	programs = {
		bash.interactiveShellInit = "if [[ -d $HOME/.bashrc.d ]]; then source $HOME/.bashrc.d/*; fi";
		dconf.enable = true;
		gnome-disks.enable = true;
		firefox.enable = true;

		steam = {
			enable = true;
			remotePlay.openFirewall = true;
			dedicatedServer.openFirewall = true;
		};

	};

	users.users.drath = {
		isNormalUser = true;
		description = "Drath Vader";
		extraGroups = [ "networkmanager" "wheel" "docker" ];
		hashedPassword = "$y$j9T$CPnmW6oj.KK.iDrtTl8wS1$0VB6QuxpSv9Xo.uKY57yb5cho691tz.UoKpgVio1um1";

		packages = with pkgs; [
			telegram-desktop
			prismlauncher
			discord
			mpv
			discordo
			spotify
			kicad
			kate
			htop
			google-cloud-sdk
			pciutils
			usbutils
			git
			vscode
			neofetch
			lm_sensors
		];
	};

	nix = {

		settings = {
			experimental-features = [ "nix-command" "flakes" ];
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

	environment.systemPackages = with pkgs; [
		libsForQt5.kirigami-addons
		libsForQt5.kaccounts-providers
		libsForQt5.kaccounts-integration
		libsForQt5.kio
		neovim
		helix
	];

	hardware = {
		bluetooth.enable = true;
		sane.enable = true;
		pulseaudio.enable = false;
		opengl = {
			driSupport = true;
			driSupport32Bit = true;
			enable = true;
			extraPackages = with pkgs; [
				intel-media-driver
				libvdpau-va-gl
				vaapiIntel
				vaapiVdpau
			];
		};
	};


	fonts = {
		enableDefaultFonts = true;
		fontconfig = {
			antialias = true;

			defaultFonts = {
				monospace = [ "Iosevka Comfy Motion" ];
				sansSerif = [ "Inter" ];
				serif = [ "IBM Plex Serif" ];
				emoji = [ "Noto Color Emoji" ];
			};

			hinting = {
				enable = true;
				style = "hintslight";
			};

			subpixel = {
				rgba = "rgb";
				lcdfilter = "default";
			};
		};

		fonts = with pkgs; [
			cantarell-fonts
			ibm-plex
			noto-fonts
			noto-fonts-cjk
			noto-fonts-emoji
			liberation_ttf
			fantasque-sans-mono
			iosevka-comfy.comfy-motion
			iosevka-comfy.comfy
			roboto-mono
			ubuntu_font_family
			inter
			fira-code
			fira-code-symbols
		];
	};

	console.keyMap = "pl2";
	nixpkgs.config.allowUnfree = true;
	sound.enable = true;
	system.stateVersion = "23.05";
	time.timeZone = "Europe/Warsaw";
	virtualisation.docker.enable = true;
}
