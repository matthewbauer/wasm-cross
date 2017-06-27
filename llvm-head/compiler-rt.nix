{ stdenv
, fetch-llvm-mirror
, cmake
, llvm
, lib
, hostPlatform
, buildPlatform
, python
}:

stdenv.mkDerivation {
  name = "compiler-rt";
  src = fetch-llvm-mirror {
    name = "compiler-rt";
    rev = "9cbbe014c4d99e31fce00f40cfbecf3799872d2e";
    sha256 = "05ndndq8sp317ig2fh88xvm6ps7whf5sy9slwfkl0s88m2k79jjp";
  };
  nativeBuildInputs = [ cmake python ];
  cmakeFlags = [
    "-DLLVM_CONFIG_PATH=${llvm}/bin/llvm-config"
    "-DCOMPILER_RT_DEFAULT_TARGET_TRIPLE=${hostPlatform.config}"
  ]
  # TODO: Figure out how to build sanitizers, etc. when cross compiling
  ++ lib.optionals (hostPlatform != buildPlatform) [ "--target" "../lib/builtins" ];

  # TSAN requires XPC on Darwin, which we have no public/free source files for. We can depend on the Apple frameworks
  # to get it, but they're unfree. Since LLVM is rather central to the stdenv, we patch out TSAN support so that Hydra
  # can build this. If we didn't do it, basically the entire nixpkgs on Darwin would have an unfree dependency and we'd
  # get no binary cache for the entire platform. If you really find yourself wanting the TSAN, make this controllable by
  # a flag and turn the flag off during the stdenv build.
  postPatch = stdenv.lib.optionalString stdenv.isDarwin ''
    substituteInPlace ./projects/compiler-rt/cmake/config-ix.cmake \
      --replace 'set(COMPILER_RT_HAS_TSAN TRUE)' 'set(COMPILER_RT_HAS_TSAN FALSE)'
  '';

  # TODO: Install sanitizers
  installPhase = ''
    mkdir -p $out/lib
    mv lib/*/libclang_rt.builtins-*.a $out/lib/libcompiler_rt.a
  '';
}