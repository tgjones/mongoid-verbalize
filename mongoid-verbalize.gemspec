lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name          = 'mongoid-verbalize'
  s.version       = '0.0.1'
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['Tim Jones']
  s.email         = ['tim@timjones.tw']
  s.homepage      = 'https://github.com/tgjones/mongoid-verbalize'
  s.summary       = 'Fine-grained versioning and localization for Mongoid documents'
  s.description   = 'Fine-grained versioning and localization for Mongoid documents'
  s.license     = "MIT"

  s.files         = Dir.glob('{lib,spec}/**/*') + %w(LICENSE README.md Rakefile Gemfile .rspec)
  s.require_path = 'lib'

  s.add_runtime_dependency('mongoid', ['< 3.0', '>= 2.0'])
  s.add_runtime_dependency('bson_ext')
  s.add_development_dependency('rake', ['>= 0.9.2'])
  s.add_development_dependency('rspec', ['~> 2.12.0'])
  s.add_development_dependency('yard', ['~> 0.8'])
end