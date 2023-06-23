{
networking.useDHCP = true;				# set by default
i18n.extraLocaleSettings.LC_TIME = "pl_PL.UTF-8";	# just sets the time format
console.keyMap = "pl2";					# not using console all that much

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
}