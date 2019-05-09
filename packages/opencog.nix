{ pkgs ? import <nixpkgs> {} }: with pkgs;

stdenv.mkDerivation rec {
  name = "opencog";

  src = fetchFromGitHub {
    owner = "opencog";
    repo = "opencog";
    rev = "cf188947294f48a5473f87adaf34250e9bcca4ef";
    sha256 = "1ngh0nal1khchmd8x4b8m2c4b7p53x6ih253k4hnif0q2pqfldpn";
  };

  cogutil = (import ./cogutil.nix {});
  atomspace = (import ./atomspace.nix {});
  link-grammar = (import ./link-grammar.nix {});
  moses = (import ./moses.nix {});

  octomap = (import ./other/octomap.nix {});
  cpprest = (import ./other/cpprest.nix {});

  netcat = (import ./other/netcat-openbsd.nix {});

  nativeBuildInputs = [
    cmake
    boost166
    cxxtest

    netcat
  ];

  buildInputs = [
    guile gmp

    cogutil
    atomspace
    link-grammar

    libuuid
    octomap

    #optional:
    moses
    python3
    python3Packages.cython
    pkgconfig
    pcre
    valgrind
    stack
    doxygen

    # deprecated or soon to be:
    # cpprest # will be removed with the new pattern miner
    # openssl # required by cpprest

    # zeromq
    # jsoncpp
    # protobuf
    # blas
    # liblapack
    # gtk3
  ];

  CPATH = "${cxxtest.src}:${atomspace.src}";
  CXXTEST_BIN_DIR = "${cxxtest}/bin";
  # ZMQ_LIBRARY="${zeromq}/lib/libzmq.so";

  GUILE_INCLUDE_DIR = "${guile.dev}/include/guile/2.2";
  GMP_INCLUDE_DIR = "${gmp.dev}/include";
  VALGRIND_INCLUDE_DIR = "${valgrind.dev}/include";

  GUILE_SITE_DIR="share/guile/site";

  # cpprest_LIBRARY = "${cpprest}/lib/libcpprest.so";
  # cpprest_version_FILE = "${cpprest}/include/cpprest/version.h";

  cmakeFlags = [
    ''-DCPATH:PATH=${CPATH}''
    ''-DCXXTEST_BIN_DIR:PATH=${CXXTEST_BIN_DIR}''

    ''-DGUILE_INCLUDE_DIR:PATH=${GUILE_INCLUDE_DIR}''
    ''-DGMP_INCLUDE_DIR:PATH=${GMP_INCLUDE_DIR}''
    ''-DVALGRIND_INCLUDE_DIR:PATH=${VALGRIND_INCLUDE_DIR}''

    ''-DGUILE_SITE_DIR:PATH=${GUILE_SITE_DIR}''

    # ''-Dcpprest_version_FILE:PATH=${cpprest_version_FILE}''
  ];

  patchPhase = ''
    mkdir -p $out/share/opencog
    cp -r ${atomspace.src}/cmake $out/share/opencog/

    THIS_DIR=$(pwd)
    mkdir .cache
    export XDG_CACHE_HOME=$THIS_DIR/.cache

    sed -i -e 's~load \\"" GUILE_SITE_DIR "/~load-from-path \\"~g' $(find . -type f)

    GUILE_LOAD_PATH="$GUILE_LOAD_PATH:${atomspace}/build"
    GUILE_LOAD_PATH="$GUILE_LOAD_PATH:${atomspace.src}/opencog/scm"
    GUILE_LOAD_PATH="$GUILE_LOAD_PATH:$THIS_DIR/build/opencog/scm"
    GUILE_LOAD_PATH="$GUILE_LOAD_PATH:${src}/tests"
    export GUILE_LOAD_PATH
  '';

  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/setup-hooks/move-lib64.sh#L6
  dontMoveLib64 = 1;

  checkPhase = ''
    make test ARGS="-V"
  '';

  doCheck = true;

  meta = with stdenv.lib; {
    description = "A framework for integrated Artificial Intelligence & Artificial General Intelligence (AGI)";
    homepage = https://wiki.opencog.org/w/Development;
    license = licenses.agpl3;
#    maintainers = with maintainers; [ radivarig ];
    platforms = with platforms; unix;
  };
}
