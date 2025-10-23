{ self, ... }:

let
  name = "elk-legacy";
  format = "hyperv";
  system = "x86_64-linux";
  ip = "144.76.176.200";
in
{
  flake.lib.${name} = {
    inherit system format ip;
  };

  seal.deploy.nodes.${name} = {
    hostname = ip;
    sshUser = "altibiz";
  };

  branch.nixosModule.nixosModule = {
    imports = [
      self.nixosModules.base
      self.nixosModules.dockerCompose
    ];

    networking.hostName = "elk-legacy";

    services.docker-compose.projects = {
      default = {
        composeFile = ./docker-compose.yml;
      };
    };
  };

  integrate.nixosConfiguration = {
    systems = [ system ];
    nixosConfiguration = {
      imports = [
        self.nixosModules.${format}
        self.nixosModules."hosts/elk-legacy"
      ];
    };
  };
}
