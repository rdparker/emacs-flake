{ emacs-vterm-src }:
self: super:
let overlays = [ (import ./emacs-vterm.nix { inherit emacs-vterm-src; }) ];
in super.lib.composeManyExtensions overlays self super
