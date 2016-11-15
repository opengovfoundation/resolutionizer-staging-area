{ region ? "us-west-2"
, accessKeyId ? "resolutionizer"
, dbUser
, dbPass
, dbName
, dbPort ? 5432
, phoenixPort ? 4000
, domainName
, s3BucketName
, legistarClient ? ""
, legistarKey ? ""
, ...
}:

let
  dbResourceName = dbName + "-db";
  s3BucketResourceName = s3BucketName + "-bucket";
  iamRoleName = s3BucketResourceName + "-access";
in {
  network.description = "resolutionizer";

  resolutionizer =
    { config, pkgs, resources, ... }:
      let
        builds = import ../default.nix { inherit pkgs; };
        serverPackage = builds.server;
        clientPackage = builds.client;
        dbHost = "${builtins.head (pkgs.lib.splitString '':'' resources.rdsDbInstances.${dbResourceName}.endpoint)}";
      in {
          imports = [ ./resolutionizer.nix ];

          resolutionizer = {
            inherit dbUser dbPass dbName dbPort phoenixPort domainName
            serverPackage clientPackage dbHost s3BucketName legistarClient
            legistarKey;
            awsRegion = region;
          };

          deployment.targetEnv = "ec2";
          deployment.ec2.region = region;
          deployment.ec2.accessKeyId = accessKeyId;
          deployment.ec2.instanceType = "t2.micro";
          deployment.ec2.securityGroups = [ "default" resources.ec2SecurityGroups.resolutionizer-group ];
          deployment.ec2.keyPair = resources.ec2KeyPairs.resolutionizer-keys;
          deployment.ec2.elasticIPv4 = resources.elasticIPs.resolutionizer-ip;
          deployment.ec2.instanceProfile = iamRoleName;
          deployment.ec2.ebsInitialRootDiskSize = 20;
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
      in map mkOpenPort [ 22 80 443 ];
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

  resources.s3Buckets.${s3BucketResourceName} = {
    inherit region accessKeyId;
    name = s3BucketName;
  };

  resources.iamRoles.${iamRoleName} = {
    inherit region accessKeyId;
    name = iamRoleName;
    policy = ''
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": [
              "s3:ListBucket"
            ],
            "Resource": [
              "arn:aws:s3:::${s3BucketName}"
            ]
          },
          {
            "Effect": "Allow",
            "Action": [
              "s3:*"
            ],
            "Resource": [
              "arn:aws:s3:::${s3BucketName}/*"
            ]
          }
        ]
      }
    '';
  };
}
