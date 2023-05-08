{
  description =
    "Emacs with Pure-GTK, vterm, yabai and system-appearance support";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    emacs-overlay.inputs.flake-utils.follows = "flake-utils";

    # Non-flakes
    emacs-patches-src.flake = false;
    emacs-patches-src.url = "github:d12frosted/homebrew-emacs-plus";

    emacs-src.flake = false;
    emacs-src.url = "github:emacs-mirror/emacs/emacs-29";

    emacs-vterm-src.flake = false;
    emacs-vterm-src.url = "github:akermu/emacs-libvterm";

    # Only used by shell.nix
    flake-compat.flake = false;
    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs = { self, nixpkgs, emacs-overlay, emacs-patches-src, emacs-src
    , emacs-vterm-src, flake-utils, ... }:
    let
      inherit (flake-utils.lib) eachDefaultSystem eachSystem;
      inherit (nixpkgs.lib) mkIf platforms;
      isDarwin = system: (builtins.elem system platforms.darwin);
    in eachDefaultSystem (localSystem:
      let
        ifDarwinElse = darwin: other:
          if (isDarwin localSystem) then darwin else other;
      in rec {
        pkgs = import nixpkgs {
          inherit localSystem;
          overlays = [
            emacs-overlay.overlays.emacs
            (final: prev:
              let
                overrideEmacs = { pkg, options ? { }, src ? pkg.src }:
                  (pkg.override options).overrideAttrs
                  (o: rec { inherit src; });
                useGtk3 = { pkg, src ? pkg.src }:
                  overrideEmacs {
                    inherit pkg src;
                    options = {
                      withGTK3 = true;
                      withNS = false;
                    };
                  };
                usePgtk = { pkg, src ? pkg.src }:
                  overrideEmacs {
                    inherit pkg src;
                    options = { withPgtk = true; };
                  };
                useNox = { pkg, src ? pkg.src }:
                  overrideEmacs {
                    inherit pkg src;
                    options = {
                      withNS = false;
                      withX = false;
                      withGTK2 = false;
                      withGTK3 = false;
                      withWebP = false;
                    };
                  };
              in rec {
                emacsGit = useGtk3 { pkg = prev.emacsGit; };
                emacsPgtk = usePgtk { pkg = prev.emacsPgtk; };
                emacsUnstable = useGtk3 { pkg = prev.emacsUnstable; };
                emacsUnstablePgtk = usePgtk { pkg = prev.emacsUnstablePgtk; };
                emacsLsp = useGtk3 { pkg = prev.emacsLsp; };
                emacsGit-nox = useNox { pkg = prev.emacsGit-nox; };
                emacsUnstable-nox = useNox { pkg = prev.emacsUnstable-nox; };

                # The Stable packages are taken from the emacs-src input.
                emacsStable = useGtk3 {
                  pkg = prev.emacsGit;
                  src = emacs-src;
                };
                emacsStablePgtk = usePgtk {
                  pkg = prev.emacsPgtk;
                  src = emacs-src;
                };
                emacsStable-nox = useNox {
                  pkg = prev.emacs-nox;
                  src = emacs-src;
                };

                emacs = emacsStable;
              })
            # The 'emacs-vterm-src' overlay must be come after any
            # overlays for ''emacs' because it adjusts changes the
            # Emacs 'postInstall' step for Emacs.
            (import ./overlays { inherit emacs-patches-src emacs-vterm-src; })
          ];
        };

        packages = rec {
          inherit (pkgs)
            emacs emacsGit emacsPgtk emacsStable emacsStablePgtk emacsUnstable
            emacsUnstablePgtk emacsLsp emacsStable-nox emacsGit-nox
            emacsUnstable-nox;
          default = emacs;
        };
      });
}
