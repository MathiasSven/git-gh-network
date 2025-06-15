{
  description = "git-gh-network flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    bashcov.url = "github:infertux/bashcov";
    # bashcov.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      inherit (builtins) head match readFile;
      inherit (pkgs)
        stdenv
        makeWrapper
        htmlq
        git
        just
        pandoc
        ;
      inherit (pkgs.lib) makeBinPath;

      pname = "git-gh-network";
      version = head (match ".*VERSION=\"([^[:space:]]*)\".*" (readFile ./src/git-gh-network));
    in
    {
      packages.${system} = {
        default = self.packages.${system}.git-gh-network;
        git-gh-network = stdenv.mkDerivation {
          inherit pname version;
          src = ./.;

          nativeBuildInputs = [
            makeWrapper
            just
            git
            pandoc
          ];

          dontBuild = true;

          justFlags = [
            "PREFIX=${placeholder "out"}"
            "SYSCONFDIR=${placeholder "out"}/share"
          ];

          # postInstall = ''
          #   wrapProgram $out/bin/git-gh-network \
          #     --prefix PATH : ${makeBinPath [ htmlq git ]}
          # '';
        };
      };

      devShell.${system} = pkgs.mkShell {
        packages = with pkgs; [
          argbash
          (bats.withLibraries (p: [
            p.bats-support
            p.bats-assert
          ]))
          inputs.bashcov.packages.${system}.bashcov
        ];

        inputsFrom = [ self.packages.${system}.default ];
      };
    };
}
