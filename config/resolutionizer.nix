{ config, lib, pkgs, ...}:

with lib;

let
  cfg = config.resolutionizer;

  useLocalPostgres = cfg.dbHost == "localhost" || cfg.dbHost == "";
in {

  options.resolutionizer = {
    dbHost = mkOption {
      type = types.str;
      default = "localhost";
      description = ''
        Where the application can connect to the database. Setting this to
        "localhost" or the empty string will setup a local database for use.
      '';
    };

    dbName = mkOption {
      type = types.str;
      default = "resolutionizer";
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
      default = "resolutionizer";
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

    awsAccessKeyId = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The access key id to use for S3 access. If not set, the application
        looks for IAM instance info, which of course won't work unless it is
        running on EC2 and the machine as been configured with an IAM role.
      '';
    };

    awsSecretAccessKey = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The access key secret to use for S3 access. If not set, the application
        looks for IAM instance info, which of course won't work unless it is
        running on EC2 and the machine as been configured with an IAM role.
      '';
    };

    enableSSL = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Automatically grab SSL certs with letsencrypt and force TLS usage
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
      ${optionalString (cfg.awsAccessKeyId != null) "AWS_ACCESS_KEY_ID=${cfg.awsAccessKeyId}"}
      ${optionalString (cfg.awsSecretAccessKey != null) "AWS_SECRET_ACCESS_KEY=${cfg.awsSecretAccessKey}"}
    '';

    environment.systemPackages = [ cfg.serverPackage pkgs.postgresql pkgs.wkhtmltopdf ];

    nixpkgs.config.allowUnfree = true;
    fonts.fonts = [ pkgs.corefonts ];
    fonts.fontconfig.ultimate.enable = false;

    services.postgresql.enable = useLocalPostgres;

    services.nginx = {
      enable = true;

      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedTlsSettings = cfg.enableSSL;
      sslProtocols = "TLSv1.2 TLSv1.1 TLSv1";
      sslCiphers = "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:ECDHE-RSA-RC4-SHA:ECDHE-ECDSA-RC4-SHA:AES128:AES256:RC4-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK";

      virtualHosts = {
        ${cfg.domainName} = {
            default = true;
            forceSSL = cfg.enableSSL;
            enableACME = cfg.enableSSL;
            acmeRoot = "/var/www/challenges";

            locations."/" = {
              root = cfg.clientPackage;
              index = "index.html";
              tryFiles = "$uri $uri/ /index.html";
            };

            locations."/api/" = {
              proxyPass = "http://phoenix_upstream";
              extraConfig = "proxy_redirect off;";
            };

            locations."/favicon.ico" = {
              tryFiles = "$uri =204";
            };
        };
      };

      appendHttpConfig = ''
        upstream phoenix_upstream {
          ip_hash;
          server 127.0.0.1:${toString cfg.phoenixPort};
        }
      '';
    };

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
          unset PGUSER
          unset PGPASSWORD
          unset PGDATABASE
          unset PGPORT
          unset PGHOST
          if ! ${pkgs.postgresql}/bin/psql -w -l | grep -q '${cfg.dbName}'; then
            ${pkgs.postgresql}/bin/createuser -w --no-superuser --no-createdb --no-createrole ${cfg.dbUser} || true
            ${pkgs.postgresql}/bin/psql -d postgres -c "ALTER USER ${cfg.dbUser} WITH PASSWORD '${cfg.dbPass}';" || true
            ${pkgs.postgresql}/bin/createdb -w --owner ${cfg.dbUser} ${cfg.dbName} || true
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
