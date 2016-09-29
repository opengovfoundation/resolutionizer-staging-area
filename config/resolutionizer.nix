{ dbUser
, dbPass
, dbName
, dbPort ? 5432
, dbHost
, webPort ? 8080
, tlsPort ? 8081
, domainName
, package
, config
, pkgs
, ...
}:

{
  networking.hostName = "resolutionizer";
  networking.firewall.allowedTCPPorts = [ 22 80 443 webPort tlsPort ];

  # Port forwarding using iptables, could alternatively do
  # http://stackoverflow.com/a/21653102, but no biggie, since we don't
  # intended on bringing the service up and down regularly
  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port ${toString webPort}
    iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port ${toString tlsPort}
  '';

  nix.gc.automatic = true;

  deployment.keys.resolutionizer-environment.text = ''
    PORT=${toString webPort}
    TLS_PORT=${toString tlsPort}
    PGUSER=${dbUser}
    PGPASS=${dbPass}
    PGDATABASE=${dbName}
    PGPORT=${toString dbPort}
    TLS_CERT_FILE=${config.security.acme.directory}/${domain}/fullchain.pem
    TLS_KEY_FILE=${config.security.acme.directory}/${domain}/key.pem
  '';

  environment.systemPackages = [ package pkgs.postgresql ];

  systemd.services.resolutionizer-server = {
    description = "resolutionizer server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    # These are set here because the expressions do not resolve
    # correctly inside the deployment.keys.* attribute, the RDS endpoint
    # is empty and the path for assets is wrong
    environment.PGHOST = "${dbHost}";
    environment.STATIC_DIRS = "[${package}/assets, /var/www/challenges]";

    serviceConfig = {
      ExecStart = "${package}/bin/resolutionizer foreground";
      Restart = "on-failure";
      User = "resolutionizer";
      Group = "resolutionizer";
      EnvironmentFile = "/run/keys/resolutionizer-environment";
    };
  };

  security.acme.certs."${domain}" = {
    webroot = "/var/www/challenges";
    email = "developers@opengovfoundation.org";
    group = "resolutionizer";
    allowKeysForGroup = true;
    postRun = "systemctl restart resolutionizer-server";
  };

  services.nixosManual.showManual = false;

  services.openssh = {
    allowSFTP = false;
    passwordAuthentication = false;
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
};
