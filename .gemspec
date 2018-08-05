Gem::Specification.new do |spec|
  spec.name        = 'babik'
  spec.version     = '0.1.0'
  spec.licenses    = ['MIT']
  spec.summary     = 'A port of Django QuerySet for Ruby on Rails'
  spec.description = 'Another way of making database queries with ActiveRecord models in Ruby on Rails based on Django QuerySets'
  spec.authors     = ['Diego J. Romero López']
  spec.email       = 'diegojromerolopez@gmail.com'
  spec.files = Dir[
      '{app,lib,config}/**/*', 'MIT-LICENSE', 'Rakefile', 'Gemfile', '*.md'
  ]
  spec.test_files = Dir['spec/**/*']
  spec.homepage    = 'https://rubygems.org/gems/babik'
  spec.metadata    = { 'source_code_uri' => 'https://github.com/diegojromerolopez/babik' }
  spec.require_path = 'lib'
  spec.add_runtime_dependency 'activerecord', '>= 5.2.0'
  spec.add_runtime_dependency 'rails'
  spec.add_runtime_dependency 'ruby_deep_clone'
  spec.add_development_dependency 'minitest', '>= 4.7.3'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'simplecov'
end

