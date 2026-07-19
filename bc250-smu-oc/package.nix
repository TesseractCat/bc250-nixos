{
  lib,
  python3Packages,
  fetchFromGitHub,
  stress
}:

python3Packages.buildPythonApplication rec {
  pname = "bc250_smu_oc";
  version = "unstable-2026-07-18";

  src = fetchFromGitHub {
    owner = "bc250-collective";
    repo = "bc250_smu_oc";
    rev = "main";
    hash = "sha256-jUeUUzc0ezs+KrRmJvg9nVR0kWW4T3pAedh8v42Zd1g=";
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