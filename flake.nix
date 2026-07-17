{
  description = "Crystal flake: dev shell/env from binaries + source build package + auto-update metadata";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;

        archMap = {
          "x86_64-linux" = "linux-x86_64";
          "aarch64-linux" = "linux-aarch64";
          "aarch64-darwin" = "darwin-universal";
        };
        arch = archMap.${system};

        # BEGIN AUTO-GENERATED CRYSTAL METADATA
        latestVersion = "1.21.0";
        binaryHashes = {
          "1.21.0" = {
            "x86_64-linux" = "sha256-dEVh7jzuGwbRBs+a6ZuAZLTgF1GKxBTW3SPPr+NlYMk=";
            "aarch64-linux" = "sha256-TzDan/CD3EhWUuPZsE1+gsxMSftuirO6x2y94k2WB3g=";
            "aarch64-darwin" = "sha256-f8SvVrDLXH6lcD90TGYpuxn/Nro6u/Iy1Q5Aw5og7hY=";
          };
        };

        binaryLibc = {
          "1.21.0" = {
            "x86_64-linux" = "musl";
            "aarch64-linux" = "musl";
            "aarch64-darwin" = "unknown";
          };
        };

        srcHashes = {
          "1.21.0" = "sha256-Xi1p9WVVOqcofnZXDUVAojG/3xo3874Xn0l+8d+KDZo=";
        };
        # END AUTO-GENERATED CRYSTAL METADATA

        binaryUrl = version: rel:
          if system == "aarch64-linux" then
            let flavor = binaryLibc.${version}.${system} or "unknown"; in
            if flavor == "musl" then
              "https://dev.alpinelinux.org/archive/crystal/crystal-v${version}-aarch64-alpine-linux-musl.tar.gz"
            else if flavor == "glibc" then
              "https://github.com/crystal-lang/crystal/releases/download/v${version}/crystal-v${version}-${toString rel}-${arch}.tar.gz"
            else
              throw "Unsupported aarch64-linux libc flavor: ${flavor}"
          else
            "https://github.com/crystal-lang/crystal/releases/download/v${version}/crystal-v${version}-${toString rel}-${arch}.tar.gz";

        crystalBinary = { version, rel ? 1 }:
          pkgs.stdenv.mkDerivation {
            pname = "crystal-binary";
            inherit version;

            src = pkgs.fetchurl {
              url = binaryUrl version rel;
              sha256 = binaryHashes.${version}.${system}
                or (throw "Missing binary hash for version=${version}, system=${system}");
            };

            nativeBuildInputs = [ pkgs.makeWrapper ];

            buildCommand = ''
              mkdir -p $out
              tar --strip-components=1 -C $out -xf $src
              patchShebangs $out/bin/crystal || true
            '';

            meta = with lib; {
              description = "Crystal binary distribution";
              platforms = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
              mainProgram = "crystal";
            };
          };

        crystalSource = { version }:
          let
            bootstrapCrystal = crystalBinary { inherit version; };
          in
          pkgs.stdenv.mkDerivation {
            pname = "crystal";
            inherit version;

            src = pkgs.fetchFromGitHub {
              owner = "crystal-lang";
              repo = "crystal";
              rev = version;
              sha256 = srcHashes.${version};
            };

            nativeBuildInputs = [
              bootstrapCrystal
              pkgs.makeWrapper
              pkgs.which
              pkgs.pkg-config
              pkgs.installShellFiles
              pkgs.llvmPackages_22.llvm
            ];

            buildInputs = [
              pkgs.boehmgc
              pkgs.pcre2
              pkgs.libevent
              pkgs.libyaml
              pkgs.zlib
              pkgs.libxml2
              pkgs.openssl
            ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.libiconv ];

            preBuild = ''
              export CRYSTAL_WORKERS=$NIX_BUILD_CORES
              export threads=$NIX_BUILD_CORES
              export LLVM_CONFIG="${pkgs.llvmPackages_22.llvm.dev}/bin/llvm-config"
              export FLAGS="--single-module"
            '';

            buildPhase = ''
              runHook preBuild
              make all docs release=1 progress=1 CRYSTAL_CONFIG_VERSION=${version}
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out/bin $out/lib/crystal $out/share/doc/crystal
              install -m755 .build/crystal $out/bin/crystal
              cp -r src/* $out/lib/crystal/
              [ -d docs ] && cp -r docs $out/share/doc/crystal/api || true
              [ -d samples ] && cp -r samples $out/share/doc/crystal/ || true

              if [ -f man/crystal.1 ]; then
                installManPage man/crystal.1
              elif [ -f share/man/man1/crystal.1 ]; then
                installManPage share/man/man1/crystal.1
              else
                echo "warning: crystal manpage not found; skipping"
              fi
              runHook postInstall
            '';

            doCheck = false;

            meta = with lib; {
              description = "Crystal language compiler built from source";
              homepage = "https://crystal-lang.org/";
              license = licenses.asl20;
              mainProgram = "crystal";
              platforms = [ system ];
            };
          };

        crystal-binary-latest = crystalBinary { version = latestVersion; };
        crystal-source-latest = crystalSource { version = latestVersion; };
      in
      {
        packages = {
          default = crystal-binary-latest;
          crystal-binary = crystal-binary-latest;
          crystal-source = crystal-source-latest;
        };

        apps.default = {
          type = "app";
          program = "${crystal-binary-latest}/bin/crystal";
        };

        devShells.default = pkgs.mkShell {
          packages = [
            crystal-binary-latest
            pkgs.git
            pkgs.pkg-config
            pkgs.llvmPackages_22.clang
            pkgs.openssl
          ];
        };
      });
}
