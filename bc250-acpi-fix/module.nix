{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.bc250-acpi-fix;
in
{
  options.services.bc250-acpi-fix = {
    enable = lib.mkEnableOption "BC-250 ACPI table overrides for CPU idle states and frequency scaling";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "Package providing the BC-250 ACPI override tables.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.boot.initrd.systemd.enable -> config.boot.loader.supportsInitrdSecrets or true;
        message = "services.bc250-acpi-fix requires an initrd the bootloader loads unmodified.";
      }
    ];

    boot.initrd.prepend = [
      "${cfg.package}/lib/firmware/acpi/acpi_override.cpio"
    ];
  };
}
