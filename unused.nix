systemd = {
		services = {
			backup-configs = {
				enable = true;
				path = with pkgs; [ pigz gnutar rclone ];
				serviceConfig = {
					Type = "oneshot";
					User = cfg.username;
				};
				description = "Backup home dir and container configuration to cloud storage";
				script = ''
					cd ~; tar -cvf - configs build           | pigz | rclone --config=/etc/rclone/rclone.conf rcat ${cfg.backup.backend}/$HOSTNAME/$HOSTNAME-configs.tar.gz
					cd ~; tar -cvf - *.sh *.yml .bashrc.d mc | pigz | rclone --config=/etc/rclone/rclone.conf rcat ${cfg.backup.backend}/$HOSTNAME/$HOSTNAME-home.tar.gz
				'';
			};
		};
		timers = {
			backup-configs = {
				enable = pkgs.lib.mkDefault true;
				wantedBy = [ "timers.target" ];
				description = "Timer to home dir and container configuration to cloud storage";
				requires = [ "backup-configs.service" ]; # fuck you
				timerConfig = {
					OnCalendar = "*-*-* 0,6,12,18:00:00";
					Unit = "backup-configs.service";
				};
			};
		};
	};