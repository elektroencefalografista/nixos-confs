{ ... }:

{
	environment.etc = {
		"restic/restic-pw" = {
			text = "StarWars9^";
			# text = "U3RhcldhcnM5Xg==";
	    	mode = "0444";
		};

		"restic/repository" = {
			text = "s3:s3.eu-central-003.backblazeb2.com/drath-restic";
			mode = "0444";
		};

		"restic/s3Credentials.env" = {
			text = "AWS_ACCESS_KEY_ID=0038dba8eb6d42d0000000006\nAWS_SECRET_ACCESS_KEY=K003exVE40qJQUSzHbg/rgf1JepUEk0";
			mode = "0444";
		};
	};
}