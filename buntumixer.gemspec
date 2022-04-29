# frozen_string_literal: true

require_relative 'lib/buntumixer/version'

Gem::Specification.new do |spec|
  spec.name = 'buntumixer'
  spec.version = Buntumixer::VERSION
  spec.authors = ['MURATA Mitsuharu']
  spec.email = ['hikari.photon+dev@gmail.com']

  spec.summary = 'Ubuntu customization tools'
  spec.description = 'This project is developing tools to customize ubuntu'
  spec.homepage = 'https://github.com/himeyama/buntumixer'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
