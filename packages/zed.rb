require 'package'

class Zed < Package
  description 'Zed is a high-performance, multiplayer code editor'
  homepage 'https://zed.dev/'
  version '0.146.5'
  license 'GPL-3, AGPL-3, Apache-2.0'
  compatibility 'x86_64'
  min_glibc '2.28'
  source_url "https://github.com/zed-industries/zed/releases/download/v#{version}/zed-linux-x86_64.tar.gz"
  source_sha256 'affa10f7db0d42a6d1fece2090c8f74a9ea4a56e5a2f1601db1224a4f29debc5'

  depends_on 'alsa_lib'
  depends_on 'libbsd'
  depends_on 'libxau'
  depends_on 'libxcb'
  depends_on 'libxdmcp'
  depends_on 'libxkbcommon'
  depends_on 'openssl'
  depends_on 'zlib'
  depends_on 'zstd'

  no_compile_needed
  no_shrink

  def self.install
    FileUtils.mkdir_p CREW_DEST_PREFIX.to_s
    FileUtils.mv 'bin/', CREW_DEST_PREFIX.to_s
    FileUtils.mv 'share/', CREW_DEST_PREFIX.to_s
    FileUtils.mv 'libexec/', CREW_DEST_PREFIX.to_s
  end

  def self.postinstall
    ExitMessage.add "\nType 'zed' to get started.\n"
  end

  def self.remove
    config_dir = "#{CREW_PREFIX}/.config/zed"
    if Dir.exist? config_dir
      print "Would you like to remove the #{config_dir} directory? [y/N] "
      case $stdin.gets.chomp.downcase
      when 'y', 'yes'
        FileUtils.rm_rf config_dir
        puts "#{config_dir} removed.".lightgreen
      else
        puts "#{config_dir} saved.".lightgreen
      end
    end
  end
end