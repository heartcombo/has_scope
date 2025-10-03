# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'has_scope/version'

Gem::Specification.new do |s|
  s.name        = 'has_scope'
  s.version     = HasScope::VERSION.dup
  s.platform    = Gem::Platform::RUBY
  s.summary     = 'Maps controller filters to your resource scopes.'
  s.email       = 'heartcombo.oss@gmail.com'
  s.homepage    = 'http://github.com/heartcombo/has_scope'
  s.description = 'Maps controller filters to your resource scopes'
  s.authors     = ['José Valim']
  s.license     = 'MIT'
  s.metadata    = {
    "homepage_uri"    => "https://github.com/heartcombo/has_scope",
    "changelog_uri"   => "https://github.com/heartcombo/has_scope/blob/main/CHANGELOG.md",
    "source_code_uri" => "https://github.com/heartcombo/has_scope",
    "bug_tracker_uri" => "https://github.com/heartcombo/has_scope/issues",
  }

  s.files         = Dir['MIT-LICENSE', 'README.md', 'lib/**/*']
  s.require_paths = ['lib']

  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = [
    'README.md'
  ]

  s.required_ruby_version = '>= 2.7.0'

  s.add_runtime_dependency 'actionpack', '>= 7.0'
  s.add_runtime_dependency 'activesupport', '>= 7.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'mocha'
end
