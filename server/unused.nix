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

	########### FILESYSTEMS ########### should i move zfs here?

	boot.zfs.extraPools = [ "zpool" ];

	fileSystems = {
		"/mnt/mfs_share" = {
			device = "/dev/disk/by-uuid/cdb15f8d-7a83-4b33-aaf7-e4147261900a";
			fsType = "btrfs";
			options = [ 
				"relatime" 
				"nofail"
				"defaults"
				"x-systemd.mount-timeout=15" ];
		};

		"/mnt/mfs_anime" = {
			device = "/dev/disk/by-uuid/f4ecfce7-0ff2-4f1f-9709-de874618fe58";
			fsType = "btrfs";
			options = [ 
				"relatime" 
				"nofail"
				"defaults"
				"x-systemd.mount-timeout=15" ];
		};

		"/mnt/mfs_purple" = {
			device = "/dev/disk/by-uuid/557885a9-7107-43d2-bab8-109a36b351af";
			fsType = "ext4";
			options = [ 
				"relatime" 
				"nofail"
				"defaults"
				"x-systemd.mount-timeout=15" ];
		};

		"/mnt/anime" = {
			device = "/mnt/mfs_*:/mnt/zpool";
			fsType = "fuse.mergerfs";
			options = [ 
				"defaults" 
				"nonempty"
				"allow_other"
				"use_ino"
				"category.create=msplfs"
				"dropcacheonclose=true"
				"minfreespace=10G"
				"fsname=mfs_pool"
				"nofail" ];
			depends = [ "/mnt/zpool" "/mnt/mfs_anime" ];
			noCheck = true;
		};

	};
}