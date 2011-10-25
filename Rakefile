require 'bundler'
Bundler::GemHelper.install_tasks

task :default => [:spec]
task :test => [:spec]

desc "Run the test suite"
task :spec do
  exec "rspec spec/"
end
