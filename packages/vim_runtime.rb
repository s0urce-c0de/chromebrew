require 'buildsystems/autotools'

class Vim_runtime < Autotools
  description 'Vim is a highly configurable text editor built to make creating and changing any kind of text very efficient. (shared runtime)'
  homepage 'https://www.vim.org/'
  version '9.1.0969'
  license 'GPL-2'
  compatibility 'all'
  source_url 'https://github.com/vim/vim.git'
  git_hashtag "v#{version}"
  binary_compression 'tar.zst'

  binary_sha256({
    aarch64: '5b1749cf3c34088c8baf184b89a1e40a45a0a2476bcf848656a6fb3d5fd848f1',
     armv7l: '5b1749cf3c34088c8baf184b89a1e40a45a0a2476bcf848656a6fb3d5fd848f1',
       i686: '8d3859465b7c125c6a308bb04b0bf30b814d0a1941ace996888361ebfffdc96f',
     x86_64: '7afa5a9906e79de6f4a02dec474d9313ff8c97b20d63bf5bd07ce70a3c955fa3'
  })

  depends_on 'gpm' # R
  depends_on 'libsodium' # R
  depends_on 'termcap' # R

  def self.patch
    # set the system-wide vimrc path
    FileUtils.cd('src') do
      system 'sed', '-i', "s|^.*#define SYS_VIMRC_FILE.*$|#define SYS_VIMRC_FILE \"#{CREW_PREFIX}/etc/vimrc\"|",
             'feature.h'
      system 'sed', '-i', "s|^.*#define SYS_GVIMRC_FILE.*$|#define SYS_GVIMRC_FILE \"#{CREW_PREFIX}/etc/gvimrc\"|",
             'feature.h'
    end
  end

  configure_options "--localstatedir=#{CREW_PREFIX}/var/lib/vim \
    --with-features=huge \
    --with-compiledby='Chromebrew' \
    --enable-gpm \
    --enable-acl \
    --with-x=no \
    --disable-gui \
    --enable-multibyte \
    --enable-cscope \
    --enable-netbeans \
    --enable-perlinterp=dynamic \
    --enable-pythoninterp=dynamic \
    --enable-python3interp=dynamic \
    --enable-rubyinterp=dynamic \
    --enable-luainterp=dynamic \
    --enable-tclinterp=dynamic \
    --disable-canberra \
    --disable-selinux \
    --disable-nls"

  def self.install
    @vim_version = version.rpartition('.')[0].sub('.', '')
    system 'make', "VIMRCLOC=#{CREW_PREFIX}/etc", "DESTDIR=#{CREW_DEST_DIR}", 'install'

    # bin and man will be provided by the 'vim' packages
    FileUtils.rm_r "#{CREW_DEST_PREFIX}/bin"
    FileUtils.rm_r "#{CREW_DEST_PREFIX}/share/man"

    # remove desktop and icon files for the terminal package
    FileUtils.rm_r "#{CREW_DEST_PREFIX}/share/applications"
    FileUtils.rm_r "#{CREW_DEST_PREFIX}/share/icons"

    # these are provided by 'xxd_standalone'
    @deletefiles = %W[#{CREW_DEST_PREFIX}/bin/xxd #{CREW_DEST_MAN_PREFIX}/man1/xxd.1]
    @deletefiles.each do |f|
      FileUtils.rm_f f
    end

    # add sane defaults and simulate some XDG support
    FileUtils.mkdir_p("#{CREW_DEST_PREFIX}/share/vim/vimfiles")
    File.write("#{CREW_DEST_PREFIX}/share/vim/vimfiles/chromebrew.vim", <<~EOF)
      " Global vimrc - setting some sane defaults
      "
      " DO NOT EDIT THIS FILE. IT'S OVERWRITTEN UPON UPGRADES.
      "
      " Use #{CREW_PREFIX}/etc/vimrc for system-wide and ~/.vimrc for personal
      " configuration.

      " Use Vim defaults instead of 100% vi compatibility
      " Avoid side-effects when nocompatible has already been set.
      if &compatible
        set nocompatible
      endif

      " Disable automatic visual mode on mouse select.
      set mouse-=a

      set backspace=indent,eol,start
      set ruler
      set suffixes+=.aux,.bbl,.blg,.brf,.cb,.dvi,.idx,.ilg,.ind,.inx,.jpg,.log,.out,.png,.toc
      set suffixes-=.h
      set suffixes-=.obj

      " Move temporary files to a secure location to protect against CVE-2017-1000382
      if exists('$XDG_CACHE_HOME')
        let &g:directory=$XDG_CACHE_HOME
      else
        let &g:directory=$HOME . '/.cache'
      endif
      let &g:undodir=&g:directory . '/vim/undo//'
      let &g:backupdir=&g:directory . '/vim/backup//'
      let &g:directory.='/vim/swap//'
      " Create directories if they doesn't exist
      if ! isdirectory(expand(&g:directory))
        silent! call mkdir(expand(&g:directory), 'p', 0700)
      endif
      if ! isdirectory(expand(&g:backupdir))
        silent! call mkdir(expand(&g:backupdir), 'p', 0700)
      endif
      if ! isdirectory(expand(&g:undodir))
        silent! call mkdir(expand(&g:undodir), 'p', 0700)
      endif
    EOF
    system "sed -i 's/set mouse=a/set mouse-=a/g' #{CREW_DEST_PREFIX}/share/vim/vim#{@vim_version}/defaults.vim"
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/etc"
    vimrc = "#{CREW_DEST_PREFIX}/etc/vimrc"
    # by default we will load the global config
    File.write(vimrc, <<~VIMRCEOF)
      " System-wide defaults are in #{CREW_PREFIX}/share/vim/vimfiles/chromebrew.vim
      " and sourced by this file. If you wish to change any of those settings, you
      " should do so at the end of this file or in your user-specific (~/.vimrc) file.

      " If you do not wish to use the bundled defaults, remove the next line.
      runtime! chromebrew.vim
    VIMRCEOF
  end
end
