# Adds emacs-vterm to nixpkgs and adds its supporting Emacs Lisp file
# and library module to Emacs so that it is automatically available.
{ emacs-vterm-src }:
self: super: {
  emacs-vterm = super.stdenv.mkDerivation rec {
    pname = "emacs-vterm";
    version = "master";

    src = emacs-vterm-src;

    nativeBuildInputs = [ super.cmake super.libtool super.glib.dev ];

    buildInputs = [ super.glib.out super.libvterm-neovim super.ncurses ];

    cmakeFlags = [ "-DUSE_SYSTEM_LIBVTERM=yes" ];

    preConfigure = ''
      echo "include_directories(\"${super.glib.out}/lib/glib-2.0/include\")" >> CMakeLists.txt
      echo "include_directories(\"${super.glib.dev}/include/glib-2.0\")" >> CMakeLists.txt
      echo "include_directories(\"${super.ncurses.dev}/include\")" >> CMakeLists.txt
      echo "include_directories(\"${super.libvterm-neovim}/include\")" >> CMakeLists.txt
    '';

    installPhase = ''
      mkdir -p $out
      cp ../vterm-module.so $out
      cp ../vterm.el $out
    '';
  };

  emacs = (super.emacs.override { }).overrideAttrs (oa: {
    postInstall = oa.postInstall + ''
      cp ${self.emacs-vterm}/vterm.el $out/share/emacs/site-lisp/vterm.el
      cp ${self.emacs-vterm}/vterm-module.so $out/share/emacs/site-lisp/vterm-module.so
    '';
  });
}
