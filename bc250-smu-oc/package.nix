{
  lib,
  python3Packages,
  fetchFromGitHub,
  stress,
}:

python3Packages.buildPythonApplication rec {
  pname = "bc250_smu_oc";
  version = "unstable-2026-09-27";

  src = fetchFromGitHub {
    owner = "bc250-collective";
    repo = "bc250_smu_oc";
    rev = "327014d6515d7108b1144adfa7203b4cc2eefd0b";
    hash = "sha256-YKzdUiDJRoEubvms263DD6CfaZhj8S5kigOoIS+shfA=";
  };

  pyproject = true;

  nativeBuildInputs = with python3Packages; [
    setuptools
  ];

  propagatedBuildInputs = [
    stress
  ];

  meta = with lib; {
    description = "CPU Overclocking Tools for AMD BC-250 via SMU messages";
    homepage = "https://github.com/bc250-collective/bc250_smu_oc";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}