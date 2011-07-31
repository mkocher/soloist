# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "soloist/version"

Gem::Specification.new do |s|
  s.name        = "ahamid-soloist"
  s.version     = Soloist::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matthew Kocher"]
  s.email       = ["kocher@gmail.com"]
  s.homepage    = "http://github.com/ahamid/soloist"
  s.summary     = %q{Soloist is a simple way of running chef-solo}
  s.description = %q{Soloist is an easy way of running chef solo, but it's not doing much.}

  s.rubyforge_project = "soloist"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "chef"
  s.add_dependency "json", ">= 1.4.4", "<= 1.5.2"
end
