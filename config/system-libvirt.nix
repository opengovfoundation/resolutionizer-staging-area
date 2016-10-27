{ dbUser
, dbPass
, dbName
, dbPort ? 5432
, phoenixPort ? 4000
, awsRegion
, s3BucketName
, domainName
, awsAccessKeyId
, awsSecretAccessKey
, ...
}:

{
  network.description = "resolutionizer";

  resolutionizer =
    { config, pkgs, resources, ... }:
      let
        builds = import ../default.nix { inherit pkgs; };
        serverPackage = builds.server;
        clientPackage = builds.client;
        dbHost = "localhost";
      in
        {
          imports = [ ./resolutionizer.nix ];

          resolutionizer = {
            inherit dbUser dbPass dbName dbPort phoenixPort domainName
            serverPackage clientPackage dbHost s3BucketName awsRegion
            awsAccessKeyId awsSecretAccessKey;
            enableSSL = false;
          };

          deployment.targetEnv = "libvirtd";
          deployment.libvirtd.imageDir = "/var/lib/libvirt/images";
          deployment.libvirtd.headless = true;
        };
}
