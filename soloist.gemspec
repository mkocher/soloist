# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "soloist/version"

Gem::Specification.new do |s|
  s.name        = "soloist"
  s.version     = Soloist::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matthew Kocher", "Doc Ritezel"]
  s.email       = ["kocher@gmail.com", "ritezel@gmail.com"]
  s.homepage    = "http://github.com/mkocher/soloist"
  s.summary     = "Soloist is a simple way of running chef-solo"
  s.description = "Makes running chef-solo easy."

  s.rubyforge_project = "soloist"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "chef"
  s.add_dependency "librarian-chef"
  s.add_dependency "thor"
  s.add_dependency "hashie", "~> 1.2"
  s.add_dependency "net-ssh"
  s.add_dependency "awesome_print"

  s.add_development_dependency "rspec"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "guard-bundler"
  s.add_development_dependency "guard-shell"
  s.add_development_dependency "rb-fsevent"
  s.add_development_dependency "terminal-notifier-guard"
  s.add_development_dependency "gem-release"
  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
end
