{ pkgs, ... }:

{
  seal.defaults.devShell = "dev";
  integrate.devShell = {
    devShell = pkgs.mkShell {
      packages = with pkgs; [
        # Nix
        nil
        nixfmt-rfc-style

        # Scripts
        just
        nushell

        # Bash
        nodePackages.bash-language-server
        shfmt

        # Misc
        nodePackages.prettier
        nodePackages.yaml-language-server
        nodePackages.vscode-langservers-extracted
        markdownlint-cli
        nodePackages.markdown-link-check
        marksman
        taplo

        # Tools
        nixos-generators
        openssh
        sshpass
      ];
    };
  };
}
