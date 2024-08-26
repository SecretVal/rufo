{
  description = "Example kickstart Rust application project.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        lib,
        ...
      }: let
        inherit (pkgs) dockerTools rustPlatform;
        inherit (dockerTools) buildImage;
        inherit (rustPlatform) buildRustPackage;
        name = "rufo";
        version = "0.1.0";
        buildInputs = with pkgs; [
          udev
          alsa-lib
          vulkan-loader
          xorg.libX11
          xorg.libXcursor
          xorg.libXi
          xorg.libXrandr
          libxkbcommon
          wayland
        ];
        nativeBuildInputs = with pkgs; [
          pkg-config
        ];
      in {
        devShells = {
          default = pkgs.mkShell {
            inputsFrom = [self'.packages.default];
            LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;
          };
        };

        packages = {
          default = buildRustPackage {
            inherit version;
            cargoSha256 = "sha256-OiAQhlQDTRqMELTO1ZUEvM5cNibghqJjfYrGL/nTVcc=";
            pname = name;
            src = ./.;
            inherit buildInputs;
            inherit nativeBuildInputs;
          };

          docker = buildImage {
            inherit name;
            tag = version;
            config = {
              Cmd = ["${self'.packages.default}/bin/${name}"];
              Env = [
                "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
              ];
            };
          };
        };
      };
    };
}
