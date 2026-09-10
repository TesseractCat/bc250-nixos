{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.hardware.bc250-mesa;
in
{
  options.hardware.bc250-mesa = {
    enable = lib.mkEnableOption "patched Mesa exposing the BC-250 compute queue";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "Package providing the patched Mesa.";
    };

    package32 = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pkgsi686Linux.callPackage ./package.nix { };
      description = "Package providing the patched 32-bit Mesa.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.hardware.bc250-amdgpu.enable;
        message = ''
          hardware.bc250-mesa requires hardware.bc250-amdgpu.enable. The
          patched Mesa hangs the GPU on an unpatched kernel driver.
        '';
      }
    ];

    hardware.graphics.package = cfg.package;
    hardware.graphics.package32 = lib.mkIf config.hardware.graphics.enable32Bit cfg.package32;
  };
}
