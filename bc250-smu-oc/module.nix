{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.bc250-cpu-oc;
in {
  options.services.bc250-cpu-oc = {
    enable = mkEnableOption "bc250_smu_oc CPU overclocking and undervolting service";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "The bc250_smu_oc package to use.";
    };

    configFile = mkOption {
      type = types.path;
      default = "/etc/overclock.conf";
      description = "Path to the generated overclock configuration file.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.services.bc250-cpu-oc = {
      description = "Apply AMD BC-250 CPU Overclock/Undervolt Settings";
      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${cfg.package}/bin/bc250-apply --apply ${cfg.configFile}";
      };
    };
  };
}