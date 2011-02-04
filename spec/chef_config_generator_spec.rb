require 'rspec'
require 'lib/soloist'

describe "ChefConfigGenerator" do
  describe "generation" do
    before do
      @config = <<-CONFIG
Cookbook_Paths:
- ./chef/cookbooks/
Recipes:
- pivotal_workstation::ack
CONFIG
      @generator = ChefConfigGenerator.new(@config, "../..")
      FileUtils.stub(:pwd).and_return("/current/working/directory")
    end

    it "appends the current path and relative path to the cookbooks directory" do
      @generator.cookbook_paths.should == ["/current/working/directory/../.././chef/cookbooks/"]
    end
  
    it "can generate a solo.rb contents" do
      @generator.solo_rb.should == 'cookbook_path ["/current/working/directory/../.././chef/cookbooks/"]'
    end
  
    it "can generate the json contents" do
      @generator.json_hash.should == {
        "recipes" => ['pivotal_workstation::ack']
      }
    end
  
    it "can generate json files" do
      JSON.parse(@generator.json_file).should == {
        "recipes" => ['pivotal_workstation::ack']
      }
    end
  end
  
  describe "yaml config values" do
    before do
      FileUtils.stub(:pwd).and_return("/")
    end
      
    it "accepts Cookbook_Paths, because the CamelSnake is a typo that must be supported" do
      @config = "Cookbook_Paths:\n- ./chef/cookbooks/\n"
      @generator = ChefConfigGenerator.new(@config, "")
      @generator.cookbook_paths.should == ["///./chef/cookbooks/"]
    end
    
    it "accepts cookbook_paths, because it is sane" do
      @config = "cookbook_paths:\n- ./chef/cookbooks/\n"
      @generator = ChefConfigGenerator.new(@config, "")
      @generator.cookbook_paths.should == ["///./chef/cookbooks/"]
    end
    
    it "accepts Recipes, because that's the way it was" do
      @config = "Recipes:\n- pivotal_workstation::ack"
      @generator = ChefConfigGenerator.new(@config, "")
      @generator.json_hash.should == { "recipes" => ["pivotal_workstation::ack"]}
    end

    it "accepts recipes, because it's snake now" do
      @config = "recipes:\n- pivotal_workstation::ack"
      @generator = ChefConfigGenerator.new(@config, "")
      @generator.json_hash.should == { "recipes" => ["pivotal_workstation::ack"]}
    end
  end
      
  
  describe "environment variable merging" do
    before do
      @config = <<-CONFIG
cookbook_paths:
- ./chef/cookbooks/
recipes:
- pivotal_workstation::ack
env_variable_switches:
  RACK_ENV:
    development:
      cookbook_paths:
      - ./chef/dev_cookbooks/
      recipes:
      - pivotal_dev::foo
      CONFIG
      FileUtils.stub(:pwd).and_return("/")
    end

    it "merges in if the variable is set to the the value" do
      ENV["RACK_ENV"]="development"
      @generator = ChefConfigGenerator.new(@config, "../..")
      @generator.cookbook_paths.should == [
        "//../.././chef/cookbooks/",
        "//../.././chef/dev_cookbooks/"
        ]
      @generator.json_hash["recipes"].should == [
        "pivotal_workstation::ack", 
        "pivotal_dev::foo"
        ]
    end
  end     
end