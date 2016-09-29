{ region ? "us-west-2"
, accessKeyId ? "resolutionizer"
, dbUser
, dbPass
, dbName
, dbPort ? 5432
, webPort ? 8080
, tlsPort ? 8081
, ...
}:

{
  network.description = "resolutionizer";

  resolutionizer =
    { config, pkgs, resources, ... }:
      let
        build = import ./default.nix { };
        package = build.resolutionizer;
        domain = "test.mymadison.io";
      in
        {
          deployment.targetEnv = "ec2";
          deployment.ec2.region = region;
          deployment.ec2.accessKeyId = accessKeyId;
          deployment.ec2.instanceType = "t2.micro";
          deployment.ec2.securityGroups = [ resources.ec2SecurityGroups.resolutionizer ];
          deployment.ec2.keyPair = resources.ec2KeyPairs.resolutionizer-keys;
          deployment.ec2.elasticIPv4 = resources.elasticIPs.resolutionizer;

          inherit (import ./resolutionizer.nix {
            inherit config pkgs dbUser dbPass dbName dbPort webPort tlsPort domain package;
            dbHost = "${builtins.head (pkgs.lib.splitString '':'' resources.rdsDbInstances.${dbName}.endpoint)}";
          });
        };

  resources.ec2KeyPairs.resolutionizer-keys = { inherit region accessKeyId; };
  resources.elasticIPs.resolutionizer = { inherit region accessKeyId; };

  resources.ec2SecurityGroups.resolutionizer = {
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

  resources.rdsDbInstances.${dbName} = {
    inherit region accessKeyId dbName;
    id = builtins.replaceStrings ["_"] [""] dbName;
    instanceClass = "db.t2.micro";
    allocatedStorage = 20;
    masterUsername = dbUser;
    masterPassword = dbPass;
    port = dbPort;
    engine = "postgres";
  };
}
