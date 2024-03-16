require 'package'

class Llvm18_build < Package
  description 'The LLVM Project is a collection of modular and reusable compiler and toolchain technologies. The optional packages clang, lld, lldb, polly, compiler-rt, libcxx, and libcxxabi are included.'
  homepage 'http://llvm.org/'
  version '18.1.0'
  license 'Apache-2.0-with-LLVM-exceptions, UoI-NCSA, BSD, public-domain, rc, Apache-2.0 and MIT'
  compatibility 'all'
  source_url 'https://github.com/llvm/llvm-project.git'
  git_hashtag "llvmorg-#{version}"
  binary_compression 'tar.zst'

  binary_sha256({
    aarch64: 'f548be260db7eb878403b78b1dedff69504326b67bb52a5cc4d7e3ca6f0ea6fe',
     armv7l: 'f548be260db7eb878403b78b1dedff69504326b67bb52a5cc4d7e3ca6f0ea6fe',
       i686: 'f68d85c167ad644911e67569e3252d971eb3c7eadfccbed4eca0f5df094081f9',
     x86_64: '502d8904eeaff5f0e1e7a510803cad4ce92580cc3613e7c929f8ff87921f150a'
  })

  depends_on 'ccache' => :build
  depends_on 'elfutils' # R
  depends_on 'gcc_lib' # R
  depends_on 'glibc' # R
  depends_on 'libedit' # R
  depends_on 'libffi' # R
  depends_on 'libxml2' # R
  depends_on 'llvm18_dev' => :build
  depends_on 'ncurses' # R
  depends_on 'ocaml' => :build
  depends_on 'py3_pygments' => :build
  depends_on 'py3_pyyaml' => :build
  depends_on 'xzutils' # R
  depends_on 'zlibpkg' # R
  depends_on 'zstd' # R

  no_env_options
  conflicts_ok

  case ARCH
  when 'aarch64', 'armv7l'
    # LLVM_TARGETS_TO_BUILD = 'ARM;AArch64;AMDGPU'
    # LLVM_TARGETS_TO_BUILD = 'all'.freeze
    @ARCH_C_FLAGS = "-fPIC -mfloat-abi=hard -mthumb -mfpu=vfpv3-d16 -march=armv7-a+fp -ccc-gcc-name #{CREW_BUILD}"
    @ARCH_CXX_FLAGS = "-fPIC -mfloat-abi=hard -mthumb -mfpu=vfpv3-d16 -march=armv7-a+fp -ccc-gcc-name #{CREW_BUILD}"
    @ARCH_LDFLAGS = ''
    @ARCH_LTO_LDFLAGS = "#{@ARCH_LDFLAGS} -flto=thin"
    LLVM_PROJECTS_TO_BUILD = 'clang;clang-tools-extra;compiler-rt;libclc;lld;lldb;polly;pstl'.freeze
  when 'i686'
    # LLVM_TARGETS_TO_BUILD = 'X86'.freeze
    # Because ld.lld: error: undefinler-rt;libc;libcxx;libcxxabi;libunwind;openmped symbol: __atomic_store
    # Polly demands fPIC
    @ARCH_C_FLAGS = '-latomic -fPIC'
    @ARCH_CXX_FLAGS = '-latomic -fPIC'
    # Because getting this error:
    # ld.lld: error: relocation R_386_PC32 cannot be used against symbol isl_map_fix_si; recompile with -fPIC
    # So as per https://github.com/openssl/openssl/issues/11305#issuecomment-602003528
    @ARCH_LDFLAGS = '-Wl,-znotext'
    @ARCH_LTO_LDFLAGS = "#{@ARCH_LDFLAGS} -flto=thin"
    # lldb fails on i686 due to requirement for a kernel > 4.1.
    # See https://github.com/llvm/llvm-project/issues/57594
    LLVM_PROJECTS_TO_BUILD = 'clang;clang-tools-extra;compiler-rt;libclc;lld;lldb;polly;pstl'.freeze
  when 'x86_64'
    # LLVM_TARGETS_TO_BUILD = 'X86;AMDGPU'
    # LLVM_TARGETS_TO_BUILD = 'all'.freeze
    @ARCH_C_FLAGS = '-fPIC'
    @ARCH_CXX_FLAGS = '-fPIC'
    @ARCH_LDFLAGS = ''
    @ARCH_LTO_LDFLAGS = "#{@ARCH_LDFLAGS} -flto=thin"
    LLVM_PROJECTS_TO_BUILD = 'bolt;clang;clang-tools-extra;compiler-rt;libclc;lld;lldb;polly;pstl'.freeze
  end
  @ARCH_C_LTO_FLAGS = "#{@ARCH_C_FLAGS} -flto=thin"
  @ARCH_CXX_LTO_FLAGS = "#{@ARCH_CXX_FLAGS} -flto=thin"
  # flang isn't supported on 32-bit architectures.
  # openmp is its own package.
  # LLVM_PROJECTS_TO_BUILD = 'clang;clang-tools-extra;libcxx;libcxxabi;libunwind;lldb;compiler-rt;lld;polly;openmp'.freeze

  # Using Targets 'all' for non-i686 because otherwise mesa complains.
  # This may be patched upstream as per
  # https://reviews.llvm.org/rG1de56d6d13c083c996dfd44a32041dacae037d66
  LLVM_TARGETS_TO_BUILD = 'all'.freeze

  def self.patch
    # This patch should be in 18.0.1.
    # https://github.com/llvm/llvm-project/pull/84230
    downloader 'https://github.com/llvm/llvm-project/commit/bb22eccc90d0e8cb02be5d4c47a08a17baf4d242.patch', '3a97108033890957acf0cce214a6366b77b61caf5a4aa5a5e75d384da7f2dde1'
    system 'patch -F3 -p1 -i bb22eccc90d0e8cb02be5d4c47a08a17baf4d242.patch'

    # llvm 18.x backport.
    downloader 'https://github.com/llvm/llvm-project/pull/84290.patch', 'a54bedaa078a2bf1778e66195e016f6794a431e8622a45ee7a49bc0ca898b82b'
    system 'patch -F3 -p1 -i 84290.patch'

    # Remove rc suffix on final release.
    system "sed -i 's,set(LLVM_VERSION_SUFFIX rc),,' llvm/CMakeLists.txt"

    return unless ARCH == 'i686'

    # Patch for LLVM 15 because of https://github.com/llvm/llvm-project/issues/58851
    File.write 'llvm_i686.patch', <<~LLVM_PATCH_EOF
      --- a/clang/lib/Driver/ToolChains/Linux.cpp	2022-11-30 15:50:36.777754608 -0500
      +++ b/clang/lib/Driver/ToolChains/Linux.cpp	2022-11-30 15:51:57.004417484 -0500
      @@ -314,6 +314,7 @@ Linux::Linux(const Driver &D, const llvm
             D.getVFS().exists(D.Dir + "/../lib/libc++.so"))
           addPathIfExists(D, D.Dir + "/../lib", Paths);

      +  addPathIfExists(D, concat(SysRoot, "#{CREW_LIB_PREFIX}"), Paths);
         addPathIfExists(D, concat(SysRoot, "/lib"), Paths);
         addPathIfExists(D, concat(SysRoot, "/usr/lib"), Paths);
       }
    LLVM_PATCH_EOF
    system 'patch -Np1 -i llvm_i686.patch'
  end

  def self.build
    ############################################################
    puts "Building LLVM Targets: #{LLVM_TARGETS_TO_BUILD}".lightgreen
    puts "Building LLVM Projects: #{LLVM_PROJECTS_TO_BUILD}".lightgreen
    ############################################################

    unless Dir.exist?('builddir')
      FileUtils.mkdir_p 'builddir'
      File.write 'builddir/clc', <<~CLC_EOF
        #!/bin/bash
        machine=$(gcc -dumpmachine)
        version=$(gcc -dumpversion)
        gnuc_lib=#{CREW_LIB_PREFIX}/gcc/${machine}/${version}
        clang -B ${gnuc_lib} -L ${gnuc_lib} "$@"
      CLC_EOF
      File.write 'builddir/clc++', <<~CLCPLUSPLUS_EOF
        #!/bin/bash
        machine=$(gcc -dumpmachine)
        version=$(gcc -dumpversion)
        cxx_sys=#{CREW_PREFIX}/include/c++/${version}
        cxx_inc=#{CREW_PREFIX}/include/c++/${version}/${machine}
        gnuc_lib=#{CREW_LIB_PREFIX}/gcc/${machine}/${version}
        clang++ -fPIC  -rtlib=compiler-rt -stdlib=libc++ -cxx-isystem ${cxx_sys} -I ${cxx_inc} -B ${gnuc_lib} -L ${gnuc_lib} "$@"
      CLCPLUSPLUS_EOF
      system "mold -run cmake -B builddir -G Ninja llvm \
            -DCMAKE_ASM_COMPILER_TARGET=#{CREW_BUILD} \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_COMPILER=$(which clang) \
            -DCMAKE_C_COMPILER_LAUNCHER=ccache \
            -DCMAKE_C_COMPILER_TARGET=#{CREW_BUILD} \
            -DCMAKE_C_FLAGS='#{@ARCH_C_LTO_FLAGS}' \
            -DCMAKE_CXX_COMPILER=$(which clang++) \
            -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
            -DCMAKE_CXX_FLAGS='#{@ARCH_CXX_LTO_FLAGS}' \
            -DCMAKE_EXE_LINKER_FLAGS='#{@ARCH_LTO_LDFLAGS}' \
            -DCMAKE_INSTALL_LIBDIR=#{ARCH_LIB} \
            -DCMAKE_INSTALL_PREFIX=#{CREW_PREFIX} \
            -DCMAKE_LINKER=$(which ld.lld) \
            -D_CMAKE_TOOLCHAIN_PREFIX=llvm- \
            -DCOMPILER_RT_BUILD_BUILTINS=ON \
            -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
            -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
            -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
            -DLIBOMP_ENABLE_SHARED=ON \
            -DLIBOMP_INSTALL_ALIASES=OFF \
            -DLIBUNWIND_C_FLAGS='-fno-exceptions -funwind-tables' \
            -DLIBUNWIND_CXX_FLAGS='-fno-exceptions -funwind-tables' \
            -DLIBUNWIND_SUPPORTS_FNO_EXCEPTIONS_FLAG=ON \
            -DLIBUNWIND_SUPPORTS_FUNWIND_TABLES_FLAG=ON \
            -DLLVM_BINUTILS_INCDIR='#{CREW_PREFIX}/include' \
            -DLLVM_BUILD_LLVM_DYLIB=ON \
            -DLLVM_CCACHE_BUILD=ON \
            -DLLVM_DEFAULT_TARGET_TRIPLE=#{CREW_BUILD} \
            -DLLVM_ENABLE_FFI=ON \
            -DLLVM_ENABLE_LTO=Thin \
            -DLLVM_ENABLE_PROJECTS='#{LLVM_PROJECTS_TO_BUILD}' \
            -DLLVM_ENABLE_RTTI=ON \
            -DLLVM_ENABLE_RUNTIME=all \
            -DLLVM_ENABLE_TERMINFO=ON \
            -DLLVM_INCLUDE_BENCHMARKS=OFF \
            -DLLVM_INSTALL_UTILS=ON \
            -DLLVM_LIBDIR_SUFFIX='#{CREW_LIB_SUFFIX}' \
            -DLLVM_LINK_LLVM_DYLIB=ON \
            -DLLVM_OPTIMIZED_TABLEGEN=ON \
            -DLLVM_TARGETS_TO_BUILD='#{LLVM_TARGETS_TO_BUILD}' \
            -DOPENMP_ENABLE_LIBOMPTARGET=OFF \
            -DPYTHON_EXECUTABLE=$(which python3) \
            -Wno-dev"
    end
    @counter = 1
    @counter_max = 20
    loop do
      break if Kernel.system "mold -run #{CREW_NINJA} -C builddir -j #{CREW_NPROC}"

      puts "Make iteration #{@counter} of #{@counter_max}...".orange

      @counter += 1
      break if @counter > @counter_max
    end
  end

  def self.install
    system "DESTDIR=#{CREW_DEST_DIR} #{CREW_NINJA} -C builddir install"
    Dir.chdir('builddir') do
      FileUtils.install 'clc', "#{CREW_DEST_PREFIX}/bin/clc", mode: 0o755
      FileUtils.install 'clc++', "#{CREW_DEST_PREFIX}/bin/clc++", mode: 0o755
      FileUtils.mkdir_p "#{CREW_DEST_LIB_PREFIX}/bfd-plugins"
      Dir.chdir("#{CREW_DEST_LIB_PREFIX}/bfd-plugins") do
        FileUtils.ln_s "../../lib#{CREW_LIB_SUFFIX}/LLVMgold.so", 'LLVMgold.so'
      end
      # libunwind.* conflicts with libunwind package
      FileUtils.rm Dir.glob("#{CREW_DEST_LIB_PREFIX}/libunwind.*")
    end
  end

  # preserve for check, skip check for current version
  def self.check
    # Dir.chdir('builddir') do
    # system 'samu check-llvm || true'
    # system 'samu check-clang || true'
    # system 'samu check-lld || true'
    # end
  end

  def self.postinstall
    puts
    puts "To compile programs, use 'clang' or 'clang++'.".lightblue
    puts
    puts 'To avoid the repeated use of switch options,'.lightblue
    puts "try the wrapper scripts 'clc' or 'clc++'.".lightblue
    puts
    puts 'For more information, see http://llvm.org/pubs/2008-10-04-ACAT-LLVM-Intro.pdf'.lightblue
    puts
  end
end