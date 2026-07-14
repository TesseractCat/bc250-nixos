{
  description = "Custom NixOS packages flake";

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
  in 
  { 
    nixosModules.bc250 = { config, lib, pkgs, ... }: import ./default { inherit config lib pkgs; };
        devShells.${system}.default = pkgs.mkShell {
        name = "bc250-dev";
    };

  };
  
}