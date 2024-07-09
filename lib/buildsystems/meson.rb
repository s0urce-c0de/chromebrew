require 'package'

class Meson < Package
  property :meson_options, :pre_meson_options, :meson_install_extras

  def self.build
    puts "Additional meson_options being used: #{@pre_meson_options.nil? ? '<no pre_meson_options>' : @pre_meson_options} #{@meson_options.nil? ? '<no meson_options>' : @meson_options}".orange
    @crew_meson_options = @no_lto ? CREW_MESON_OPTIONS.sub('-Db_lto=true', '-Db_lto=false') : CREW_MESON_OPTIONS
    @mold_linker_prefix_cmd = CREW_LINKER == 'mold' ? 'mold -run' : ''
    system "#{@pre_meson_options} #{@mold_linker_prefix_cmd} meson setup #{@crew_meson_options} #{@meson_options} builddir"
    system 'meson configure --no-pager builddir'
    system "#{CREW_NINJA} -C builddir"
  end

  def self.install
    system "DESTDIR=#{CREW_DEST_DIR} #{CREW_NINJA} -C builddir install"
    @meson_install_extras&.call
  end

  def self.check
    puts "Testing with #{CREW_NINJA} test.".orange if @run_tests
    system "#{CREW_NINJA} -C builddir test" if @run_tests
  end
end
