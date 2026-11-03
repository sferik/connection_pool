require "bundler/gem_tasks"
require "standard/rake"
require "rake/testtask"
Rake::TestTask.new

task default: [:"standard:fix", :test]

task :bench do
  require_relative "test/benchmarks"
end

begin
  require "duel/rake_task"
  Duel::RakeTask.new
rescue LoadError
  # Duel requires Ruby 3.4 or later
end
