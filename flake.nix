{
  description = "Custom NixOS packages flake";

inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
};
  outputs = { self, nixpkgs, config }:

    {
    nixosModules.bc250 = { config, lib, ... }: 
      import ./default { inherit config lib; };

  };
  nixosModules.bc250.meta = {
    description = "Simple NixOS module for BC250.";
    platforms = [ "x86_64-linux" ];
    maintainers = ["TesseractCat"];
  };
}