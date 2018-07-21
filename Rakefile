# inside tasks/test.rake
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs.push 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = ENV['warning']
  t.verbose = ENV['verbose']
end

task default: :test

desc 'Run tests'
task :test do
  ENV['ENV'] = 'test'
  Rake::Task['test'].execute
end

desc 'Generates a coverage report'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['test'].execute
end