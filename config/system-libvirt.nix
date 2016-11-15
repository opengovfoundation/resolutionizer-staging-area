{ awsRegion
, s3BucketName
, domainName
, awsAccessKeyId
, awsSecretAccessKey
, legistarClient ? ""
, legistarKey ? ""
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
        dbPass = "test";
      in
        {
          imports = [ ./resolutionizer.nix ];

          resolutionizer = {
            inherit dbPass domainName serverPackage clientPackage s3BucketName
            awsRegion awsAccessKeyId awsSecretAccessKey legistarClient
            legistarKey;
            enableSSL = false;
          };

          deployment.targetEnv = "libvirtd";
          deployment.libvirtd.imageDir = "/var/lib/libvirt/images";
          deployment.libvirtd.headless = true;
        };
}
