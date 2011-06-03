# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "soloist/version"

Gem::Specification.new do |s|
  s.name        = "soloist"
  s.version     = Soloist::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matthew Kocher"]
  s.email       = ["kocher@gmail.com"]
  s.homepage    = "http://github.com/mkocher/soloist"
  s.summary     = %q{Soloist is a simple way of running chef-solo}
  s.description = %q{Soloist is an easy way of running chef solo, but it's not doing much.}

  s.rubyforge_project = "soloist"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('chef', '0.9.12')
  s.add_dependency('json', '1.4.6')
end