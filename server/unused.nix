{
networking.useDHCP = true;							# set by default
i18n.extraLocaleSettings.LC_TIME = "pl_PL.UTF-8";	# just sets the time format
console.keyMap = "pl2";								# not using console all that much

		# we have samba at home
		samba-wsdd.enable = true;
		samba = {
			enable = true;
			openFirewall = true;
			securityType = "user";
			extraConfig = ''
				server min protocol = SMB3
				workgroup = WORKGROUP
				server string = server
    			netbios name = server
    			security = user 
    			use sendfile = yes
    			hosts allow = 192.168.1. 100. 127.0.0.1 localhost
    			hosts deny = 0.0.0.0/0
    			guest account = nobody
    			map to guest = bad user
			'';
			shares = {
				anime = {
					path = "/mnt/anime";
					"valid users" = "drath";
					"guest ok" = "no";
					"read only" = "no";
					browseable = "yes";
					"create mask" = "0644";
   				    "directory mask" = "0755";
      				"force user" = "drath";
      				# "force group" = "drath";
				};
				movies = {
					path = "/mnt/anime/Jellyfin";
					"guest ok" = "yes";
					"read only" = "yes";
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