{
  description = "NixOS configuration for Hakula's machines";

  # ============================================================================
  # Inputs
  # ============================================================================
  inputs = {
    # Nixpkgs - NixOS 25.05 stable release
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # macOS system configuration
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # User environment management
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative disk partitioning (Linux only)
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ============================================================================
  # Outputs
  # ============================================================================
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      disko,
      home-manager,
      nix-darwin,
      agenix,
      ...
    }@inputs:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [
            agenix.overlays.default
          ];
        };
    in
    {
      # ========================================================================
      # NixOS Configurations (Linux servers)
      # ========================================================================
      nixosConfigurations = {
        # ----------------------------------------------------------------------
        # CloudCone SC2 (Scalable Cloud Compute)
        # ----------------------------------------------------------------------
        cloudcone-sc2 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            agenix.nixosModules.default
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.hakula = import ./home/hakula.nix;
                backupFileExtension = "bak";
              };
            }
            ./hosts/cloudcone-sc2
          ];
        };
      };

      # ========================================================================
      # Darwin Configurations (macOS)
      # ========================================================================
      darwinConfigurations = {
        # ----------------------------------------------------------------------
        # Hakula's MacBook Pro
        # ----------------------------------------------------------------------
        hakula-macbook = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs; };
          modules = [
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.hakula = import ./home/hakula.nix;
                backupFileExtension = "bak";
              };
            }
            ./hosts/hakula-macbook
          ];
        };
      };

      # ========================================================================
      # Home Manager Configurations (standalone, for non-NixOS Linux)
      # ========================================================================
      homeConfigurations = {
        # ----------------------------------------------------------------------
        # Generic Linux (e.g., Ubuntu WSL)
        # ----------------------------------------------------------------------
        hakula-linux = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor "x86_64-linux";
          extraSpecialArgs = { inherit inputs; };
          modules = [
            ./home/hakula.nix
          ];
        };
      };

      # ========================================================================
      # Formatter (nix fmt)
      # ========================================================================
      formatter = forAllSystems (system: (pkgsFor system).nixfmt-rfc-style);
    };
}
