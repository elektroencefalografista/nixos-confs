# This module defines a small NixOS installation CD.  It does not
# contain any graphical stuff.

# TODO maybe show blkid on tty1 after boot?

{ config, pkgs, ... }:

{
	imports = [
		<nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
		<nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
	];

	boot.supportedFilesystems = [ "zfs" "btrfs" ];

	# nix.settings.experimental-features = [ "nix-command" ];
	environment.systemPackages = with pkgs; [
		wget
		rclone
		parted
	];  

	programs.bash.interactiveShellInit = ''
		lsblk
		while ! ip a sh dev eth0 | grep -F "inet "; do sleep 1; done
		echo IP address is: $(ip -f inet -br a sh dev eth0 | tr -s " " | cut -f3 -d " ")
	'';

	networking.hostName = "nixos-live"; # Define your hostname.
	systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
	users.users.root.openssh.authorizedKeys.keys = [
		"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzDj37fIBKkVd+b1rq5HhgS2GBiIEIh7L/09XwFPw+OsY6IqNji51HDJape6XuOzc1ey7HuQNX64JsHM8fFJFXm8J3prhIP0MwnJgPLtXxOBLGL5x5JTw1yeAYZXEykB4W32rtqqXDhq8gU3/49w6N+wcMpn1XcsTMPlL8eeavTQlvVlHzr8ijiDO+teval8+0KtGvPOGwMNs+otFauh8DAZI/5bFk1yDxaZo2C6tlKmLATjbqx3CdUXdiA4auzpDHb4q+AZywPflJIaEHLXv+FDax/pW9eoKBEYVtrxJHYQvaog9vCm1ZS6a2kyJpFuUBN0EWtkE5WXv11mkh+DwR5zmllIVyB+BNdxERWixXEc9Hh7pgjkc7Yc2VrSexrPrmJsXU/g2lL5+v8PGZb6JBr4Z7WM99Yhf2JbLpiJ2EPB/ynqnO+bvs7Ik5pPW8pHpXUwaKu/AaKRLbE3sSHpXD/25M9B9wP4AduASqQkCXNT/U0AgpEyV1weys7UGgHns= drath@MOTHERSHIP"
		"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDp8J8KX2i3hCr8s7GJ+Yq2sY1NI252pD3FGwhiSCOATs3xckUqLXSMEJWS+jFLkq6S+oXAVNKkCmUa1jVKJg0slP4Fy/hH50QjsasJglWNZJgbls4fwcNFoBmb2S/7GKPOQFGnVtuKLtnnbxPGUYzLTVbJZORXdV4jc0ChyetdQdvKIgpPYqWKkYkpRhbQ+DnEXgQ7zi20vpDzuAWbBzrqt4aQrIq0KhaWSAJvSKUF88qqVkmp0e7yD9Rf3XwmBP/AQDTBlVzhX/sgEMmO/orvYBFHQ6etDs25L/TuPIczTaKEochIat+0qzW/ZuOHjiADsYaARNI+zwefwlR2H7UnwwZC1FY6PXRaPjribIlI8KVnRVby7aJMKlzXH235WjqdUkYWG2L9CM2cGFnEoGesz4gwmC4r6a53kRarVICezrwnCtLDHLiEzfT7PJ07jujPCsIZ9iKoZt98irlYSw3nXcxV6UYCBnQzJ2e/RRmIpR0Bv7lexaf7AF4FZuktkFk= drath@desktop"
		"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDSbAgVbfQZJFrI1i3NnCPHJRAfB4b/f7/pjE3T/7RvaLUH0vd7PR1PtvHkMl6vGJULVBA7coXjmlb1mJ/NPCsjdJg71VxJD2Wjm0lFeyPnm41aCHn3Pi7vbyib9i8xaZtflxkufpjrAZ/PeKNxMivIdFySH3aKelkvNYoTjGj4+oPhzpRTu1TJinAtqJACSvY4z0zNbADW1QqFabuRet8oCAUnWeMKTUrX1h+TSNOCo7BAM7EMaWl7+Wuahc4uAWuAhTcPmxJMW50G4WWxexdyy8sSUnrbH+ohgwkS/ZnePelDApfbIPkBDW0vKoVXKjTSDgm9awEHscVqF6OZv+lC8tZ10WjBHIC+tLLEAHTkSSIJM3XBsl9ohEmPmlbcz7tWaM5x12XLDMVgzT9cus/ArMmrpY091FRGZWr6GQH5YTfzPFMMNZncVIgpB41prZdIudhROxlemv8RGTyWfbhSn+Dp1xqsKRW6kuU9KIM97G49Ruzmq+sIwW/TgSE5Uy8= drath@DESKTOP-91HBU1O"
		"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDmfY5w2m8MxWbr1b5Af821LtP9UCOjV7KtiSguld8juw7ApfIQHlhrUdCpE1XqU6x8guKjFBnH37o3THd9tV/S6lB8vPd9mUL6rIdex7gu4hjUGopQ0FZ7XObuYcSuk43Ro4IHfHMB0OaL3OC73ndyJExFohnpM+cOGka17G8Vam/tJnZRuFflT+M9JLYTcvn2hkGDmKGMoMtyLJBLIWBnAd3auTRfPHxPw9UQt6aDYbaC+mvms0tk5SGXdPWjff2QUTb9KxNuNOlywiok69P7OSEfw/2NV1bzbm2QiPBfEplTdyCgEqKU2Rydq9JR0zG552pt5Po/6ySI631aazrgZUMN1cba+kveiR+3ef72WqJHr2Mp4sEzTBIZrajd6fzX8lxiwZj3gPV+zvV4XB9eeDrecJVAWM4l4utS7i4/dvDXsAKaj19tx0CjsUX19RR2oqJSjHFy05r3W1sonWq6iCE3JGOh4Yc1HM09U/QJC9wtXRFT14oxMN3eL2x9hP8= drath@x220.lan"
		"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCZ5r2SBA0kM6JGAJ4v0+y10D7n1ADhhf0bCcHE5Xqasr8jsvojYBuUuclXiJ3f0K5Bc85oBCV+HP+/Lx0rcWjCowsAOKCIsVgqsfccqUGlxp7DNqzWZo8Vx5RTShu0Nun0bFYXrUki8Q9sUFQJIbOSt9u9MR0gQQ9p2n8+LgGraX17tNvo/hStifzLtnpHcCW6QYuG3qcqawdOO7wmCTRHSAhWoNR43rlwijWf/QVnXDcY7KdKa1VDSg8X6Xd+vw05S4THExQtg6sYMZ9+y46PZ/hYUCqoF/16kKCFwX1uaWw/ew5F9KHcEUSJAlXUzS1VHznaskchM2Fh+D6YrTgxBW9pVqT4wfVb71LrJTVrcxBlx9TsmXRQ/r/kb4JFrb0c79lSVQV7IL9k5tact2cMwDlkXhsXTbhXVqvAqOWafeAvDZzhXtflqSSIh5Vb6c9xK/gjx73EUIVnamYzxCFVVAKRyHiLUghStpYix5lhnhI76nVdR7vUVsW4AggZG/0= nexus9@localhost"
		"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7QgLGHpPJ/ZpLkHdule3kaz8IAfmslbPrMOJkrhQSJI/OdIFotPeGKOI5hAjCTEHiVto9wlMXTSP2t8pWIaeaL+dw0SH/n698z9tVoRzQkKi6ahVqiblMMqJMPCjYdjNY0UKZcpt3UgKEvtIyonDD/b4ueQvP590h6VZ2RWmnQVP8egOpj5rKqZanUwg9B2F8HN9NaBIwlBhBqHzJi9CDOlTDVadsZJUy/w34DvRfdgJfOEm0KVZo6oejEOgs3hXZLcMAXma450jgTUt2MpqWkGt5dttoigSw1sWG0L/QOcNDJIA+KhJTdHbGajZBq0PTqxIEWMd9B05aZaRPEKWTEcnjcXkZ/AF+/UHfa8GI/lTkpz0mt6Zxn0CXoL6OfvcmwdGaGlREu45NgrI79Q3jqwN0NbyuvIDUQtFnPlTgJBydSDvJ5hhXZU4o8onX/R5C3el/hvhKHYqO7/Og5Pud6jFGyuBiU3D+Ff9ojU0c0VQiGiytiiKkvHJ5ZuWVlkc= drath@s23"
	];

	isoImage.squashfsCompression = "zstd";
	system.stateVersion = "23.05";
}
