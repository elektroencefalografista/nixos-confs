{ config, pkgs, ... }:

{	
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
				enable = true; # maybe it would be better to explicitly include systemd.user.timers.backup-configs.enable = true; in each host
				wantedBy = [ "timers.target" ];
				description = "Timer to backup scripts and configs to google drive";
				timerConfig = {
					OnCalendar = "*-*-* 0,6,12,18:00:00";
					Unit = "backup-configs.service";
				};
			};
		};
	};
}