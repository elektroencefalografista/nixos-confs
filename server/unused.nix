{
networking.useDHCP = true;							# set by default
i18n.extraLocaleSettings.LC_TIME = "pl_PL.UTF-8";	# just sets the time format
console.keyMap = "pl2";								# not using console all that much


		# tsdb path is hardcoded to be under /var/lib, have to use docker
		services.prometheus = {
			enable = true;
			scrapeConfigs = [{
				job_name = "telegraf";
				static_configs = [{
					targets = [ "127.0.0.1:9273" ];
				}];
			}];
			extraFlags = [
				"--storage.tsdb.retention.size=8GB"
				"--storage.tsdb.path=/var/promdb/"
			];
		};

		user = {
			services = {
				oneshot-config-downloader = {
					enable = true;
					path = [ pkgs.pigz pkgs.gnutar pkgs.rclone ];
					after = [ "rclone-config-downloader.service" ];
					serviceConfig.Type = "oneshot";
					unitConfig.ConditionPathExists = "!%S/%N.stamp";
					serviceConfig.RemainAfterExit = "yes";
					scriptArgs = "%S %N ${cfg.oneshotConfigDownloaderSource}";
					script = ''
						mkdir -p $1
						rclone cat google:backup/$3/$3-docker-compose.tar.gz | pigz -d | tar -x -C ~ && \
						rclone cat google:backup/$3/$3-home-dir.tar.gz | pigz -d | tar -x -C ~ && \
						rclone cat google:backup/$3/$3-configs.tar.gz | pigz -d | tar -x -C ~ && \
						touch $1/$2.stamp
					'';
					description = "Download homedir files from google drive";
					wantedBy = [ "default.target" ];
				};

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
					description = "Download rclone config";
					wantedBy = [ "default.target" ]; # this is what actually makes it run on boot
				};
			};
		};
}