# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'guides_style_18f/version'

Gem::Specification.new do |s|
  s.name          = 'guides_style_18f'
  s.version       = GuidesStyle18F::VERSION
  s.authors       = ['Mike Bland']
  s.email         = ['michael.bland@gsa.gov']
  s.summary       = '18F Guides Template style elements'
  s.description   = (
    'Provides consistent style elements for documents based on the ' \
    '18F Guides Template (https://guides-template.18f.gov/). ' \
    'The 18F Guides theme is based on ' \
    'DOCter (https://github.com/cfpb/docter/) from ' \
    'CFPB (http://cfpb.github.io/).'
  )
  s.homepage      = 'https://github.com/18F/guides-style'
  s.license       = 'CC0'

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test)}i) }
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename f }

  # requires https://github.com/jekyll/jekyll/pull/5364
  s.add_runtime_dependency 'jekyll', '~> 3.3'
  s.add_runtime_dependency 'jekyll_pages_api'
  s.add_runtime_dependency 'jekyll_pages_api_search'
  s.add_development_dependency 'go_script'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'codeclimate-test-reporter'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rubocop'
end
