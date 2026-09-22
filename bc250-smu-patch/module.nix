{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.bc250-smu-patch;
  py = pkgs.python3Packages.python;

  # The initrd only gets what we list, so list every path the package and
  # its interpreter need.
  closureOf = rootPaths:
    let
      info = pkgs.closureInfo { inherit rootPaths; };
    in
    lib.filter (p: p != "") (lib.splitString "\n" (builtins.readFile "${info}/store-paths"));
in
{
  options.services.bc250-smu-patch = {
    enable = lib.mkEnableOption "Apply AMD BC-250 SMU SRAM patches during early boot";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "Package providing bc250-smu-apply.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.boot.initrd.systemd.enable;
        message = "services.bc250-smu-patch requires boot.initrd.systemd.enable";
      }
    ];

    warnings = lib.optional
      (!config.hardware.bc250-amdgpu.enable)
      "services.bc250-smu-patch is enabled without the amdgpu patches (hardware.bc250-amdgpu.enable); 8-core telemetry will read incorrectly.";

    boot.initrd.systemd.storePaths = closureOf [ cfg.package py ];

    boot.initrd.systemd.services.bc250-smu-patch = {
      description = "Apply BC-250 SMU SRAM patches";
      wantedBy = [ "initrd.target" ];
      before = [ "initrd-root-device.target" ];

      unitConfig = {
        DefaultDependencies = false;
        # Escape hatch: append bc250.nosmupatch at the bootloader to skip.
        ConditionKernelCommandLine = "!bc250.nosmupatch";
      };

      serviceConfig = {
        Type = "oneshot";
        StandardOutput = "journal+console";
        StandardError = "journal+console";
        ExecStart = lib.getExe cfg.package;

        # The interpreter is a separate store path that isn't pulled into
        # the initrd automatically, so fail clearly if it's missing.
        ExecStartPre = "${pkgs.coreutils}/bin/test -x ${py.interpreter}";
      };
    };
  };
}
