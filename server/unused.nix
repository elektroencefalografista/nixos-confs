{
networking.useDHCP = true;							# set by default
i18n.extraLocaleSettings.LC_TIME = "pl_PL.UTF-8";	# just sets the time format
console.keyMap = "pl2";								# not using console all that much

		# we have samba at home
		services.samba = {
			enable = true;
			shares = {
				public = {
					path = "/mnt/anime";
					browseable = "yes";
				};
			};
		};

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
}