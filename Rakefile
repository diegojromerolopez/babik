# inside tasks/test.rake
require 'rake/testtask'

desc 'Run tests'
Rake::TestTask.new(:test) do |t|
  t.libs.push 'test'
  t.pattern = 'test/**/*_test.rb'
  t.warning = ENV['warning']
  t.verbose = ENV['verbose']
end

desc 'Generates a coverage report'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['test'].execute
end

task default: :test