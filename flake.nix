{
  description = "Florian's macOS system config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-spotlight = {
      url = "github:anntnzrb/nix-spotlight";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nix-darwin, nixpkgs, home-manager, nix-spotlight, ... }:
    let
      system = "aarch64-darwin";
      pkgs   = nixpkgs.legacyPackages.${system};
    in {
      darwinConfigurations."florianjonas-mbp-cern" = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          ./darwin.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs   = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules   = [ nix-spotlight.homeManagerModules.default ];
            home-manager.users.florianjonas = import ./home.nix;
          }
        ];
      };

      devShells.${system} = {
        hep = import ./devshells/hep.nix { inherit pkgs; };
        "hep-python" = import ./devshells/hep-python.nix { inherit pkgs; };
      };
    };
}
