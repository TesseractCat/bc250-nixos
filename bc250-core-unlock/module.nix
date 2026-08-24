{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.bc250-core-unlock;
in
{
  options.services.bc250-core-unlock = {
    enable = lib.mkEnableOption "BC-250 CPU core unlock during early boot";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "Package providing bc250-core-unlock.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.boot.initrd.systemd.enable;
        message = ''
          services.bc250-core-unlock requires boot.initrd.systemd.enable, as the
          unlock runs as a systemd unit in the initrd.
        '';
      }
    ];

    boot.initrd.systemd.storePaths = [ (lib.getExe cfg.package) ];

    boot.initrd.systemd.services.bc250-core-unlock = {
      description = "Unlock BC-250 CPU cores";
      wantedBy = [ "initrd.target" ];
      before = [ "initrd-root-device.target" ];

      unitConfig = {
        DefaultDependencies = false;
        # Escape hatch: append bc250.nocoreunlock at the bootloader to skip.
        ConditionKernelCommandLine = "!bc250.nocoreunlock";
      };

      serviceConfig = {
        Type = "oneshot";
        StandardOutput = "journal+console";
        ExecStart = lib.getExe cfg.package;
      };
    };
  };
}
