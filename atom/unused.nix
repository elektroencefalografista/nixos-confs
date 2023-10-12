	services = {
		grafana = {
			enable = false;
			provision = {
				enable = true;
				datasources.settings.datasources = [{
					name = "Server";
					type = "prometheus";
					url = "http://localhost:9090";
				}];
				# dashboards.path = "/path"; # maybe we could have a default, read-only dashboard? TODO? 
				# maybe download dashboard from git/grafana, place it in some dir, point this option to the dir
			};
			settings = {
				server = {
					http_addr = "0.0.0.0";
					http_port = 3000;
				};
				security = {
					admin_user = "drath";
					admin_email = "drathvader@wp.pl";
				};
			};

		};

		prometheus = {
			enable = false;
			retentionTime = "365d";
			port = 9091;
			globalConfig = {
				scrape_interval = "15s";
				evaluation_interval = "15s";
			};
			scrapeConfigs = [{
				job_name = "telegraf";
				scrape_interval = "15s";
				static_configs = [{
					targets = [ "192.168.1.200:9273" ];
				}];
			}];
			extraFlags = [
				"--storage.tsdb.retention.size=32GB"
			];
		};

		cloudflared = {
			enable = true;
			tunnels = {
				"29bb852d-8363-4728-8acc-14fe66f5b8d8" = {
					credentialsFile = "/etc/cloudflared_tunnel.json";
					default = "http_status:404";
					originRequest.noTLSVerify = true;
					ingress = {
						# "grafana.drath.cc" = "http://localhost:3000";
						"portainer.drath.cc" = "https://localhost:9433"; # idk about making this one public
						"precious.drath.cc" = "http://localhost:1111";
					};
				};
			};
		};
	};

		environment.etc = {
			"cloudflared_tunnel.json" = {
				mode = "0644";
				source = "/home/${cfg.username}/configs/cloudflared/29bb852d-8363-4728-8acc-14fe66f5b8d8.json";
			};