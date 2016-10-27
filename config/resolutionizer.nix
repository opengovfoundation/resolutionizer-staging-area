{ config, lib, pkgs, ...}:

with lib;

let
  cfg = config.resolutionizer;

  useLocalPostgres = cfg.dbHost == "localhost" || cfg.dbHost == "";
in {

  options.resolutionizer = {
    dbHost = mkOption {
      type = types.str;
      description = ''
        Where the application can connect to the database.
      '';
    };

    dbName = mkOption {
      type = types.str;
      description = ''
        The database to use.
      '';
    };

    dbPass = mkOption {
      type = types.str;
      description = ''
        The password to use when connecting to the database.
      '';
    };

    dbPort = mkOption {
      type = types.int;
      default = 5432;
      description = ''
        The port to use when connecting to the database.
      '';
    };

    dbUser = mkOption {
      type = types.str;
      description = ''
        The database user to use when connecting to the database.
      '';
    };

    phoenixPort = mkOption {
      type = types.int;
      default = 4000;
      description = ''
        The port the server part of the application should be listening on.
      '';
    };

    serverPackage = mkOption {
      type = types.package;
      description = ''
        The package containing the server application.
      '';
    };

    clientPackage = mkOption {
      type = types.package;
      description = ''
        The package containing the client files.
      '';
    };

    domainName = mkOption {
      type = types.str;
      example = "demo.example.org";
      description = ''
        The domain to acquire TLS certificates for and to use as the
        application's url in server generated messages.
      '';
    };

    s3BucketName = mkOption {
      type = types.str;
      description = ''
        The bucket name to store generated content in.
      '';
    };

    awsRegion = mkOption {
      type = types.str;
      example = "us-west-2";
      description = ''
        The AWS region the S3 bucket is in.
      '';
    };
  };

  config = {
    networking.hostName = "resolutionizer";
    networking.firewall.allowedTCPPorts = [ 22 80 443 ];

    deployment.keys.resolutionizer-environment.text = ''
      PORT=${toString cfg.phoenixPort}
      PGUSER=${cfg.dbUser}
      PGPASSWORD=${cfg.dbPass}
      PGDATABASE=${cfg.dbName}
      PGPORT=${toString cfg.dbPort}
      S3_BUCKET=${cfg.s3BucketName}
      APP_URL=${cfg.domainName}
      AWS_REGION=${cfg.awsRegion}
    '';

    environment.systemPackages = [ cfg.serverPackage pkgs.postgresql pkgs.wkhtmltopdf ];

    nixpkgs.config.allowUnfree = true;
    fonts.fonts = [ pkgs.corefonts ];
    fonts.fontconfig.ultimate.enable = false;

    services.postgresql.enable = useLocalPostgres;

    services.nginx.enable = true;
    services.nginx.httpConfig = ''
      upstream phoenix_upstream {
        ip_hash;
        server 127.0.0.1:${toString cfg.phoenixPort};
      }

      server {
        server_name ${cfg.domainName};
        listen 80 default; listen [::]:80;

        location ~ /.well-known {
          root /var/www/challenges;
          allow all;
        }

        location / {
          return 302 https://$host$request_uri;
        }
      }

      server {
        server_name ${cfg.domainName};
        listen 443 ssl http2; listen [::]:443 ssl http2;

        ssl_certificate         ${config.security.acme.directory}/${cfg.domainName}/fullchain.pem;
        ssl_certificate_key     ${config.security.acme.directory}/${cfg.domainName}/key.pem;
        # resolver 8.8.8.8;
        # ssl_stapling on;
        # ssl_stapling_verify on;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 5m;
        ssl_protocols TLSv1.2 TLSv1.1 TLSv1;
        ssl_prefer_server_ciphers on;
        ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:ECDHE-RSA-RC4-SHA:ECDHE-ECDSA-RC4-SHA:AES128:AES256:RC4-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK;

        location ~ /.well-known {
          root /var/www/challenges;
          allow all;
        }

        location / {
          root ${cfg.clientPackage};
          index index.html;
          try_files $uri $uri/ /index.html;
        }

        location /api/ {
          proxy_redirect off;
          proxy_pass http://phoenix_upstream;
        }

        location = /favicon.ico {
          try_files $uri =204;
        }
      }
    '';

    systemd.services.resolutionizer-server = {
      description = "resolutionizer server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ] ++ optional useLocalPostgres "postgresql.service";
      # These are set here because the expressions do not resolve
      # correctly inside the deployment.keys.* attribute, the RDS endpoint
      # is empty
      environment.PGHOST = "${cfg.dbHost}";
      environment.DBURL="postgres://${cfg.dbUser}:${cfg.dbPass}@${cfg.dbHost}:${toString cfg.dbPort}/${cfg.dbName}";

      preStart = ''
        ${optionalString useLocalPostgres ''
          if ! ${pkgs.sudo}/bin/sudo ${pkgs.postgresql}/bin/psql -l | grep -q '${cfg.dbName}'; then
            ${pkgs.sudo}/bin/sudo ${pkgs.postgresql}/bin/createuser --no-superuser --no-createdb --no-createrole ${cfg.dbUser} || true
            ${pkgs.sudo}/bin/sudo ${pkgs.postgresql}/bin/psql -d postgres -c "ALTER USER ${cfg.dbUser} WITH PASSWORD '${cfg.dbPass}';" || true
            ${pkgs.sudo}/bin/sudo ${pkgs.postgresql}/bin/createdb --owner ${cfg.dbUser} ${cfg.dbName} || true
          fi
        ''}
      '';

      serviceConfig = {
        ExecStart = "${cfg.serverPackage}/bin/resolutionizer foreground";
        Restart = "on-failure";
        User = "resolutionizer";
        Group = "resolutionizer";
        EnvironmentFile = "/run/keys/resolutionizer-environment";
        PermissionsStartOnly = true; # preStart must be run as root
      };
    };

    security.acme.certs."${cfg.domainName}" = {
      webroot = "/var/www/challenges";
      email = "developers@opengovfoundation.org";
      group = "resolutionizer";
      allowKeysForGroup = true;
      postRun = "systemctl reload nginx.service";
    };

    services.xserver.enable = true;

    users = {
      mutableUsers = false;
      users.root.openssh.authorizedKeys.keyFiles = [ ~/.ssh/id_rsa.pub ];
    };

    users.extraUsers.resolutionizer = {
      description = "resolutionizer user";
      home = "/var/lib/resolutionizer";
      createHome = true;
    };

    users.extraGroups.resolutionizer = {
      members = ["resolutionizer"];
    };


    # Misc. stuff

    nix.gc.automatic = true;

    services.nixosManual.showManual = false;

    services.openssh = {
      allowSFTP = false;
      passwordAuthentication = false;
    };
  };
}
