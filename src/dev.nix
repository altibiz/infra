{ pkgs, ... }:

{
  seal.defaults.devShell = "dev";
  integrate.devShell = {
    devShell = pkgs.mkShell {
      ALTIBIZ_INFRA_DEPLOY_DEV_CREDENTIALS = ".creds.yml";

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
        shellcheck

        # Misc
        nodePackages.cspell
        nodePackages.prettier
        nodePackages.yaml-language-server
        nodePackages.vscode-langservers-extracted
        markdownlint-cli
        nodePackages.markdown-link-check
        marksman
        taplo

        # Tools
        nixos-generators
        deploy-rs
        openssh
        sshpass
        trufflehog
        mo
      ];
    };
  };
}
