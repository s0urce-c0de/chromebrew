require 'package'

class Gdk_base < Package
  description 'Set environment variables for autoscaling GTK applications'
  homepage 'https://gitlab.com/chromebrew/chromebrew/'
  version '1.3'
  license 'GPL-3'
  compatibility 'all'
  source_url 'SKIP'

  depends_on 'wayland_info' # L

  no_compile_needed
  print_source_bashrc

  def self.install
    gdk_base = <<~EOF
      # GDK environment variable settings

      # Do not edit this file. It will be overwritten by updates.

      GDK_BACKEND=${GDK_BACKEND:-x11}
      function roundhalves {
                    echo "$1 * 2" | bc | xargs -I@ printf "%1.f" @ | xargs -I% echo "% * .5" | bc
            }
      pxwidth=$(WAYLAND_DISPLAY=wayland-0 wayland-info -i wl_output | grep width: | grep px | head -n 1 | awk '{print $2}')
      lwidth=$(WAYLAND_DISPLAY=wayland-0 wayland-info -i zxdg_output_manager_v1 | grep logical_width:  | sed 's/,//' | awk '{print $2}')
      # echo "pxwidth: $pxwidth, lwidth: $lwidth"
      # SCALE needs to be rounded to the nearest 0.5
      # Check to see if pxwidth and lwidth are integers before calculating SCALE.
      # wayland-info on armv7l does not show lwidth, but aarch64 does.
      if [[ $pxwidth == ?(-)+([0-9]) ]] && [[ $lwidth == ?(-)+([0-9]) ]] && [[ -z "$SCALE" ]] ; then
        SCALE=$(roundhalves $(echo "scale=2 ;$lwidth / $pxwidth" | bc))
      fi
      #[[ $RESOLUTION -gt 1500 && $RESOLUTION -lt 2500 ]] && GDK_SCALE=1.5
      #[[ $RESOLUTION -ge 2500 && $RESOLUTION -lt 3500 ]] && GDK_SCALE=2
      #[[ $RESOLUTION -ge 3500 && $RESOLUTION -lt 4500 ]] && GDK_SCALE=2.5
      #[[ $RESOLUTION -ge 4500 && $RESOLUTION -lt 5500 ]] && GDK_SCALE=3
      #[[ $RESOLUTION -gt 5500 ]] && GDK_SCALE=3.5
      SCALE=${SCALE:-1}
      GDK_SCALE=$SCALE
      QT_SCALE_FACTOR=$(printf "%.2f" $(bc -l <<< "((1 / $SCALE))"))
      echo -e "Gdk_base set environment variables below:"
      echo -e "\e[1;33mSCALE=\e[1;32m"${SCALE}
      echo -e "\e[1;33mGDK_SCALE=\e[1;32m"${GDK_SCALE}
      echo -e "\e[1;33mQT_SCALE_FACTOR=\e[1;32m"${QT_SCALE_FACTOR}"\e[0m"
    EOF
    FileUtils.mkdir_p "#{CREW_DEST_PREFIX}/etc/env.d"
    File.write("#{CREW_DEST_PREFIX}/etc/env.d/09-gdk_base", gdk_base)
  end
end
