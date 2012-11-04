$: << File.expand_path("../../lib", __FILE__)

require "soloist"
require "tempfile"
require "json"

def mock_gem(name, dependencies=[])
  mock_dependencies = dependencies.map { |depenency| mock(:name => depenency) }
  mock_gemspec = mock("#{name} gemspec", :dependencies => mock_dependencies)
  Gem::Specification.stub(:find_by_name).with(name).and_return(mock_gemspec)
  Gem.stub(:searcher).and_return(mock({:find => mock_gemspec}))
end