require 'rspec'
require File.dirname(__FILE__) + '/../lib/soloist'

def mock_gem(name, dependencies=[])
  mock_dependencies = dependencies.map { |depenency| mock(:name => depenency) }
  mock_gemspec = mock("#{name} gemspec", :dependencies => mock_dependencies)
  Gem::Specification.stub(:find_by_name).with(name).and_return(mock_gemspec)
end