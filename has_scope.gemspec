# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'has_scope/version'

Gem::Specification.new do |s|
  s.name        = 'has_scope'
  s.version     = HasScope::VERSION.dup
  s.platform    = Gem::Platform::RUBY
  s.summary     = 'Maps controller filters to your resource scopes.'
  s.email       = 'opensource@plataformatec.com.br'
  s.homepage    = 'http://github.com/plataformatec/has_scope'
  s.description = 'Maps controller filters to your resource scopes'
  s.authors     = ['José Valim']
  s.license     = 'MIT'

  s.files         = Dir['MIT-LICENSE', 'README.md', 'lib/**/*']
  s.test_files    = Dir['test/**/*.rb']
  s.require_paths = ['lib']

  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = [
    'README.md'
  ]

  s.required_ruby_version = '>= 2.1.7'

  s.add_runtime_dependency 'actionpack', '>= 4.1', '< 5.2'
  s.add_runtime_dependency 'activesupport', '>= 4.1', '< 5.2'
end
