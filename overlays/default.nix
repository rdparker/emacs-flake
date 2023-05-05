{ emacs-patches-src, emacs-vterm-src }:
self: super:
with super;
let
  inherit (lib) optional platforms;
  inherit (lib.lists) any forEach;
  inherit (stdenv) isDarwin;
  darwinPatch =
    optional isDarwin (import ./darwin.nix { inherit emacs-patches-src; });
  webKitOverlay = [ (import ./webkit.nix { inherit isDarwin; }) ];
  vtermOverlay = [ (import ./emacs-vterm.nix { inherit emacs-vterm-src; }) ];
  overlays = darwinPatch ++ webKitOverlay ++ vtermOverlay;
in super.lib.composeManyExtensions overlays self super
