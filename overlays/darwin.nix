{ emacs-patches-src }:
self: super: {
  emacs = (super.emacs.override { }).overrideAttrs (oa: {
    patches = oa.patches
      ++ [ "${emacs-patches-src}/patches/emacs-29/fix-window-role.patch" ];
  });
}
