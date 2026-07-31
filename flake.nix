{
  description = "Neovim with runtime dependencies for the Markdown and zk config";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        let
          runtimeDeps = with pkgs; [
            # lazy.nvim and plugin downloads
            git
            curl
            gzip
            gnutar
            unzip

            # markdown-preview.nvim
            nodejs
            yarn
            xdg-utils

            # zk-nvim and LazyVim pickers
            zk
            direnv
            fd
            fzf
            ripgrep

            # Mason's Python packages (ruff)
            (python3.withPackages (pythonPackages: [ pythonPackages.pip ]))

            # Markdown ftplugin media helpers
            coreutils
            wl-clipboard

            # nvim-treesitter parser builds
            gcc
            gnumake
            tree-sitter
          ];
          wrappedNvim = pkgs.runCommand "nvim-wrapper" {
            nativeBuildInputs = [ pkgs.makeWrapper ];
          } ''
            mkdir -p "$out/bin"
            makeWrapper ${pkgs.neovim}/bin/nvim "$out/bin/nvim" \
              --prefix PATH : ${pkgs.lib.makeBinPath runtimeDeps}
          '';
        in
        {
          default = pkgs.buildEnv {
            name = "nvim";
            paths = runtimeDeps ++ [ wrappedNvim ];
            pathsToLink = [ "/bin" ];
          };
        }
      );
    };
}
