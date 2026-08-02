{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.cyan-skillfish-governor-smu;

  defaultPackage = pkgs.callPackage ./package.nix {};

  tomlFormat = pkgs.formats.toml {};

  configFile =
    if cfg.settings != null then
      tomlFormat.generate "cyan-skillfish-governor-smu-config.toml" cfg.settings
    else
      cfg.configFile;
in
{
  options.services.cyan-skillfish-governor-smu = {
    enable = lib.mkEnableOption "Cyan Skillfish Governor SMU";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      description = "Package providing cyan-skillfish-governor-smu.";
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      default = "${cfg.package}/share/cyan-skillfish-governor-smu/config.toml";
      defaultText = lib.literalExpression ''
        "''${config.services.cyan-skillfish-governor-smu.package}/share/cyan-skillfish-governor-smu/config.toml"
      '';
      description = ''
        Path to the TOML config file used by the governor.

        By default this uses upstream default-config.toml installed by the package.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
      description = ''
        TOML settings to generate as the governor config.

        If null, the package's upstream default-config.toml is used.
      '';
    };

    installDbusPolicy = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the upstream D-Bus system policy file from the package.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra arguments passed to cyan-skillfish-governor-smu.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
    ];

    environment.etc."cyan-skillfish-governor-smu/config.toml".source = configFile;

    services.dbus.packages = lib.mkIf cfg.installDbusPolicy [
      cfg.package
    ];

    systemd.services.cyan-skillfish-governor-smu = {
      description = "Cyan Skillfish Governor SMU";

      wantedBy = [ "multi-user.target" ];

      conflicts = [
        "cyan-skillfish-governor.service"
        "cyan-skillfish-governor-tt.service"
        "oberon-governor.service"
      ];

      after = [
        "dbus.service"
        "systemd-modules-load.service"
      ];

      wants = [
        "dbus.service"
      ];

      serviceConfig = {
        Type = "simple";
        Environment = "RUST_BACKTRACE=1";
        ExecStart = lib.escapeShellArgs (
          [
            (lib.getExe cfg.package)
            "/etc/cyan-skillfish-governor-smu/config.toml"
          ]
          ++ cfg.extraArgs
        );
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
