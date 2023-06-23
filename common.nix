# common config options that genereally dont change often

{ config, pkgs, ... }:

{
	i18n.defaultLocale = "pl_PL.UTF-8"; # need to be set explicitly
	time.timeZone = "Europe/Warsaw";

	programs.bash.interactiveShellInit = "if [[ -d $HOME/.bashrc.d ]]; then source $HOME/.bashrc.d/*; fi";

	security.sudo.wheelNeedsPassword = false; # appearently thats outdated
	users.users.drath = {
		isNormalUser = true;
		description = "drath";
		extraGroups = [ "networkmanager" "wheel" "docker" ];
		hashedPassword = "$y$j9T$bnjLbA/0fVbi7aAbrAPbS/$LjSoS.ipo.ceLyJA0t/E1ZgAj68cNhloUC0hVBBMdU5";
		openssh.authorizedKeys.keys = [
			"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSbAgVbfQZJFrI1i3NnCPHJRAfB4b/f7/pjE3T/7RvaLUH0vd7PR1PtvHkMl6vGJULVBA7coXjmlb1mJ/NPCsjdJg71VxJD2Wjm0lFeyPnm41aCHn3Pi7vbyib9i8xaZtflxkufpjrAZ/PeKNxMivIdFySH3aKelkvNYoTjGj4+oPhzpRTu1TJinAtqJACSvY4z0zNbADW1QqFabuRet8oCAUnWeMKTUrX1h+TSNOCo7BAM7EMaWl7+Wuahc4uAWuAhTcPmxJMW50G4WWxexdyy8sSUnrbH+ohgwkS/ZnePelDApfbIPkBDW0vKoVXKjTSDgm9awEHscVqF6OZv+lC8tZ10WjBHIC+tLLEAHTkSSIJM3XBsl9ohEmPmlbcz7tWaM5x12XLDMVgzT9cus/ArMmrpY091FRGZWr6GQH5YTfzPFMMNZncVIgpB41prZdIudhROxlemv8RGTyWfbhSn+Dp1xqsKRW6kuU9KIM97G49Ruzmq+sIwW/TgSE5Uy8= drath@DESKTOP-91HBU1O"
			"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDmfY5w2m8MxWbr1b5Af821LtP9UCOjV7KtiSguld8juw7ApfIQHlhrUdCpE1XqU6x8guKjFBnH37o3THd9tV/S6lB8vPd9mUL6rIdex7gu4hjUGopQ0FZ7XObuYcSuk43Ro4IHfHMB0OaL3OC73ndyJExFohnpM+cOGka17G8Vam/tJnZRuFflT+M9JLYTcvn2hkGDmKGMoMtyLJBLIWBnAd3auTRfPHxPw9UQt6aDYbaC+mvms0tk5SGXdPWjff2QUTb9KxNuNOlywiok69P7OSEfw/2NV1bzbm2QiPBfEplTdyCgEqKU2Rydq9JR0zG552pt5Po/6ySI631aazrgZUMN1cba+kveiR+3ef72WqJHr2Mp4sEzTBIZrajd6fzX8lxiwZj3gPV+zvV4XB9eeDrecJVAWM4l4utS7i4/dvDXsAKaj19tx0CjsUX19RR2oqJSjHFy05r3W1sonWq6iCE3JGOh4Yc1HM09U/QJC9wtXRFT14oxMN3eL2x9hP8= drath@x220.lan"
		];
	};
	
	systemd.user = {
		services = {
			rclone-config-downloader = {
				enable = true;
				path = [ pkgs.curl pkgs.gzip ];
				serviceConfig.Type = "oneshot";
				unitConfig.ConditionPathExists = "!%S/rclone/rclone.conf";
				serviceConfig.RemainAfterExit = "yes";
				scriptArgs = "%S";
				script = ''
					mkdir -p $1/rclone
					curl -sSL 192.168.1.1:82/?q=rclone.conf | base64 -d | gzip -d > $1/rclone/rclone.conf
				'';
				description = "Download homedir files from google drive";
				wantedBy = [ "default.target" ]; # this is what actually makes it run on boot
			};

			backup-configs = {
				enable = true;
				path = [ pkgs.pigz pkgs.gnutar pkgs.rclone ];
				serviceConfig.Type = "oneshot";
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
				timerConfig = {
					OnCalendar = "*-*-* 0,6,12,18:00:00";
					Unit = "backup-configs.service";
				};
			};
		};

	};

	services.openssh = {
		enable = true;
		settings.PasswordAuthentication = false;
		extraConfig = "AllowUsers drath@192.168.1.*\nAllowUsers drath@100.*";
	};

	system.autoUpgrade = {
		enable = true;
		allowReboot = true;
		channel = "https://channels.nixos.org/nixos-23.05";
		rebootWindow = {
			lower = "01:00";
			upper = "05:00";
		};
	};
}