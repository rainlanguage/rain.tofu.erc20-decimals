{
  description = "Flake for development workflows.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    rainix.url = "github:rainlanguage/rainix";
    rain.url = "github:rainlanguage/rain.cli";
  };

  outputs =
    { flake-utils, rainix, ... }:
    flake-utils.lib.eachDefaultSystem (system: rec {
      packages = rainix.packages.${system};
      devShells = rainix.devShells.${system};
    });
}
