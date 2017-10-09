# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wp/cli/migrator/version'

Gem::Specification.new do |spec|
  spec.name          = 'wp-cli-migrator'
  spec.version       = WP::CLI::Migrator::VERSION
  spec.authors       = ['Mike Pastore']
  spec.email         = ['mike@oobak.org']

  spec.summary       = %q{Write a short summary, because Rubygems requires one.}
  spec.homepage      = 'https://github.com/mwpastore/wp-cli-migrator#readme'
  spec.license       = 'MIT'

  spec.files         = %x{git ls-files -z}.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = %w{lib}

  spec.required_ruby_version = '>= 2.3.0'

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
