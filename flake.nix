{
  description = "Asrock AMD BC-250 NixOS flake";

  inputs = {
      nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs }:
    let 
      # Only one arch supported
      system = "x86_64-linux";
      pkgs = import nixpkgs { 
          inherit system;
          config.allowUnfree = true;
        };
      
      # Reference your package definition files
      bc250-smu-oc = pkgs.callPackage ./bc250-smu-oc/package.nix { };
      bc250-cu-live-manager = pkgs.callPackage ./bc250-cu-live-manager/package.nix { };
    in 
    { 
      # Expose the package outputs directly
      packages.${system} = {
        bc250-smu-oc = bc250-smu-oc;
        bc250-cu-live-manager = bc250-cu-live-manager;
      };

      nixosModules.bc250 = { config, lib, ... }: import ./default.nix { inherit config lib pkgs; };

      # Development environment with the packages included
      devShells.${system}.default = pkgs.mkShell {
        name = "bc250-dev";
        packages = [
          bc250-smu-oc
          bc250-cu-live-manager
          pkgs.amdgpu_top
        ];
      };

    };
  
}