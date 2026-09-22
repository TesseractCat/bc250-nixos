{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication {
  pname = "bc250-smu-patch";
  version = "unstable-2026-09-17";

  src = fetchFromGitHub {
    owner = "rw-r-r-0644";
    repo = "bc250-smu-unlock";
    rev = "f5886d015af9019a30bd402c35e011beded07b61";
    hash = "sha256-h6W/Cj4sO+bSmYhv1yoexW50tBBO0vmScbcViWM0ILM=";
  };

  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  postInstall = ''
    install -Dm755 ${./bc250-smu-apply.py} "$out/bin/bc250-smu-apply"
    substituteInPlace "$out/bin/bc250-smu-apply" \
      --replace-fail '@PYTHON@' "${python3Packages.python.interpreter}" \
      --replace-fail '@SITE@' "$out/${python3Packages.python.sitePackages}" \
      --replace-fail '@HEX@' "$out/${python3Packages.python.sitePackages}/bc250_smu/patches.hex"
  '';

  pythonImportsCheck = [ "bc250_smu" ];

  meta = with lib; {
    description = "Apply SRAM patches to the AMD BC-250 SMU (unlock + RPC + 8-core metrics)";
    homepage = "https://github.com/rw-r-r-0644/bc250-smu-unlock";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ ];
    mainProgram = "bc250-smu-apply";
  };
}
