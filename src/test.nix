{
  self,
  perch,
  nixpkgs,
  ...
}:

let
  hostNixosModules = builtins.map (name: builtins.substring 6 (-1) name) (
    builtins.filter (name: (builtins.substring 0 6 name) == "hosts/") (
      builtins.attrNames self.nixosModules
    )
  );
in
{
  config.flake.checks = builtins.listToAttrs (
    builtins.map (system: {
      name = system;
      value =
        let
          pkgs = import nixpkgs { inherit system; };
        in
        builtins.listToAttrs (
          builtins.map (nixosModule: {
            name = nixosModule;
            value = pkgs.nixosTest {
              name = "${nixosModule}-${system}";
              nodes = {
                ${nixosModule} = {
                  imports = [ self.nixosModules."hosts/${nixosModule}" ];

                  virtualisation.memorySize = 2048;
                  virtualisation.diskSize = 8192;
                };
              };
              testScript = ''
                start_all()
                node = machines[0]
                node.succeed("ping registry-1.docker.io", timeout=10)
                node.wait_for_unit("docker-compose@default.service", timeout=60)

                node.wait_until_succeeds(
                  "docker ps --format '{{.Names}} {{.Status}}'"
                    + " | grep -v 'unhealthy'"
                    + " | grep -v 'starting' >/dev/null"
                    + " && test $(docker ps --format '{{.Names}}' | wc -l)"
                      + " -eq $(docker ps --filter 'health=healthy' --format '{{.Names}}' | wc -l)",
                  timeout=300,
                )

                node.succeed("""
                  echo 'Containers:' &&
                  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
                """)
              '';
            };
          }) hostNixosModules
        );
    }) perch.lib.defaults.systems
  );
}
