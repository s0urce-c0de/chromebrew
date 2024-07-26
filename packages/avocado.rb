require 'package'
Package.load_package("#{__dir__}/avocado_framework.rb")

class Avocado < Package
  description Avocado_framework.description
  homepage Avocado_framework.homepage
  version Avocado_framework.version
  license Avocado_framework.license
  compatibility Avocado_framework.compatibility

  is_fake

  depends_on 'avocado_framework'
end
