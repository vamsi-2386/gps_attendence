{ pkgs }: {
  deps = [
    pkgs.python311
    pkgs.python311Packages.pip
    pkgs.nodejs_20
    pkgs.cmake
    pkgs.gcc
    pkgs.libX11
    pkgs.openblas
  ];

  env = {
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
      pkgs.libX11
      pkgs.openblas
    ];
    PYTHONBIN = "${pkgs.python311}/bin/python3.11";
  };
}
