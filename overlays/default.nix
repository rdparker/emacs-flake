{ emacs-patches-src, emacs-vterm-src }:
self: super:
let
  inherit (super.lib) platforms;
  overlayDarwin = super.lib.optional super.stdenv.isDarwin
    (import ./darwin.nix { inherit emacs-patches-src; });
  overlays = overlayDarwin
    ++ [ (import ./emacs-vterm.nix { inherit emacs-vterm-src; }) ];
in super.lib.composeManyExtensions overlays self super
