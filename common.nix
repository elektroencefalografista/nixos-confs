# common config options that genereally dont change often

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
		};
	};
}