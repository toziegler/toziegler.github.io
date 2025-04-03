{
  description = "Tigerbeetle development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    zig.url = "github:mitchellh/zig-overlay";
    zls= {
        url = "github:zigtools/zls/a26718049a8657d4da04c331aeced1697bc7652b";
    };
  };

  outputs = { self, nixpkgs, zig, zls }:
      let
      system = "x86_64-linux";
  pkgs = import nixpkgs {
      inherit system;
      overlays = [ zig.overlays.default ];
  };
  linuxPackages = pkgs.linuxPackages_latest;
  in {
      devShell.${system} = pkgs.mkShell {
          buildInputs = [
              linuxPackages.perf
                  pkgs.zigpkgs."0.13.0"
                  zls.packages.${system}.default
          ];

          shellHook = ''
          echo "Tigerbeetle dev"
          exec fish -C "fish_config prompt choose nim"
          '';
      };
  };
}
