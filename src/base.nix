{
  nixpkgs,
  pkgs,
  config,
  home-manager,
  lib,
  ...
}:

let
  version = "25.05";
in
{
  branch.nixosModule.nixosModule = {
    imports = [
      home-manager.nixosModules.default
    ];

    system.stateVersion = version;

    nix.registry.nixpkgs.flake = nixpkgs;
    nix.extraOptions = "experimental-features = nix-command flakes";
    nix.gc.automatic = true;
    nix.gc.options = "--delete-older-than 30d";
    nix.settings.auto-optimise-store = true;
    nix.settings.trusted-users = [ "@wheel" ];
    nix.settings.substituters = [
      "s3://nix-binary-cache?endpoint=s3.lvm.altibiz.com"
    ];
    nix.settings.trusted-public-keys = [
      "s3.lvm.altibiz.com:2joxncr8RIOfSZcVvt79MvvX3IA4ulUjdc2mkKUR1xc="
    ];
    nix.package = pkgs.nixVersions.stable;

    networking.firewall.enable = true;
    networking.firewall.allowedTCPPorts = [
      22
      80
      443
    ];

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "altibiz-infra-rebuild";
        text = ''
          nixos-rebuild switch \
            --flake github:altibiz/infra/init#"hosts/${config.networking.hostName}-${pkgs.system}" \
            "$@"
        '';
      })
    ];

    users.groups.altibiz = { };
    users.users.altibiz = {
      group = "altibiz";
      isNormalUser = true;
      initialPassword = "altibiz";
      extraGroups = [
        "docker"
        "wheel"
      ];
    };
    home-manager.users.altibiz = {
      home.stateVersion = version;

      programs.bash.enable = true;
      programs.bash.sessionVariables = {
        TERM = "xterm-256color";
      };
    };

    virtualisation.docker.enable = true;
    virtualisation.docker.autoPrune.enable = true;
    virtualisation.docker.autoPrune.dates = "weekly";
  };
}
