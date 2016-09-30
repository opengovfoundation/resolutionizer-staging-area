{ region ? "us-west-2"
, accessKeyId ? "resolutionizer"
, dbUser
, dbPass
, dbName
, dbPort ? 5432
, phoenixPort ? 4000
, ...
}:

let
  dbResourceName = dbName + "-db";
in {
  network.description = "resolutionizer";

  resolutionizer =
    { config, pkgs, resources, ... }:
      let
        builds = import ../default.nix { inherit pkgs; };
        serverPackage = builds.server;
        clientPackage = builds.client;
        dbHost = "${builtins.head (pkgs.lib.splitString '':'' resources.rdsDbInstances.${dbResourceName}.endpoint)}";
        domainName = "resolutionizer-demo.opengovfoundation.org";
      in
        {
          deployment.targetEnv = "ec2";
          deployment.ec2.region = region;
          deployment.ec2.accessKeyId = accessKeyId;
          deployment.ec2.instanceType = "t2.micro";
          deployment.ec2.securityGroups = [ resources.ec2SecurityGroups.resolutionizer-group ];
          deployment.ec2.keyPair = resources.ec2KeyPairs.resolutionizer-keys;
          deployment.ec2.elasticIPv4 = resources.elasticIPs.resolutionizer-ip;

          # inherit (import ./resolutionizer.nix {
          #   inherit config pkgs dbUser dbPass dbName dbPort phoenixPort domainName;
          #   serverPackage = builds.server;
          #   clientPackage = builds.client;
          #   dbHost = "${builtins.head (pkgs.lib.splitString '':'' resources.rdsDbInstances.${dbName}.endpoint)}";
          # });

          networking.hostName = "resolutionizer";
          networking.firewall.allowedTCPPorts = [ 22 80 443 ];

          deployment.keys.resolutionizer-environment.text = ''
            PORT=${toString phoenixPort}
            PGUSER=${dbUser}
            PGPASS=${dbPass}
            PGDATABASE=${dbName}
            PGPORT=${toString dbPort}
          '';

          environment.systemPackages = [ serverPackage pkgs.postgresql ];

          services.nginx.enable = true;
          # services.nginx.user = "resolutionizer"; # TODO: need this?
          services.nginx.httpConfig = ''
            upstream phoenix_upstream {
              ip_hash;
              server 127.0.0.1:${toString phoenixPort};
            }

            server {
              server_name ${domainName};
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
              server_name ${domainName};
              listen 443 ssl http2; listen [::]:443 ssl http2;

              ssl_certificate         ${config.security.acme.directory}/${domainName}/fullchain.pem;
              ssl_certificate_key     ${config.security.acme.directory}/${domainName}/key.pem;
              resolver 8.8.8.8;
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
                root ${clientPackage};
                index index.html;
                try_files $uri $uri/ /index.html;
              }

              location = /api/ {
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
            after = [ "network.target" ];
            # These are set here because the expressions do not resolve
            # correctly inside the deployment.keys.* attribute, the RDS endpoint
            # is empty
            environment.PGHOST = "${dbHost}";

            serviceConfig = {
              ExecStart = "${serverPackage}/bin/resolutionizer foreground";
              Restart = "on-failure";
              User = "resolutionizer";
              Group = "resolutionizer";
              EnvironmentFile = "/run/keys/resolutionizer-environment";
            };
          };

          security.acme.certs."${domainName}" = {
            webroot = "/var/www/challenges";
            email = "developers@opengovfoundation.org";
            group = "resolutionizer";
            allowKeysForGroup = true;
            postRun = "systemctl restart resolutionizer-server";
          };

          users = {
            mutableUsers = false;
            users.root.openssh.authorizedKeys.keyFiles = [ ~/.ssh/id_rsa.pub ];
          };

          users.extraUsers.resolutionizer = {
            description = "resolutionizer user";
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

  resources.ec2KeyPairs.resolutionizer-keys = { inherit region accessKeyId; };
  resources.elasticIPs.resolutionizer-ip = { inherit region accessKeyId; };

  resources.ec2SecurityGroups.resolutionizer-group = {
      inherit region accessKeyId;
      rules =
        let
          mkOpenPort = ip: {
            fromPort = ip;
            toPort = ip;
            sourceIp = "0.0.0.0/0";
          };
        in map mkOpenPort [22 80 443];
  };

  resources.rdsDbInstances.${dbResourceName} = {
    inherit region accessKeyId dbName;
    id = builtins.replaceStrings ["_"] [""] dbResourceName;
    instanceClass = "db.t2.micro";
    allocatedStorage = 20;
    masterUsername = dbUser;
    masterPassword = dbPass;
    port = dbPort;
    engine = "postgres";
  };
}
