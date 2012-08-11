require 'spec_helper'

describe Soloist::ChefConfigGenerator do
  describe "generation" do
    before do
      @config = <<-CONFIG
Cookbook_Paths:
- ./chef/cookbooks/
cookbook_gems:
- pivotal_workstation_cookbook
Recipes:
- pivotal_workstation::ack
CONFIG
      @config = YAML.load(@config)
      FileUtils.stub(:pwd).and_return("/current/working/directory")
      @generator = Soloist::ChefConfigGenerator.new(@config, "../..")
      mock_gem("pivotal_workstation_cookbook")
    end

    it "appends the current path and relative path to the cookbooks directory" do
      @generator.cookbook_paths.should == ["/current/working/directory/../.././chef/cookbooks/"]
    end

    it "does not append if an absolute path is given" do
      @config['cookbook_paths'] = ["/foo/bar"]
      @generator = Soloist::ChefConfigGenerator.new(@config, "../..")
      @generator.cookbook_paths.should == ["/foo/bar"]
    end

    describe ".solo_rb" do
      it "can generate a solo.rb contents" do
        @generator.solo_rb.should =~ %r{cookbook_path \["/current/working/directory/../.././chef/cookbooks/"}
      end

      it "should include a tempdir with pivotal_workstation in it" do
        @generator.solo_rb.match(%r{cookbook_path \[".*", "(.*)"\]})
        File.exist?("#{$1}/pivotal_workstation").should be
      end
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
    
    describe "passing env variables to chef-solo through sudo" do
      it "has a list of env variables which are passed through" do
        @generator.preserved_environment_variables.should == %w{PATH BUNDLE_PATH GEM_HOME GEM_PATH RAILS_ENV RACK_ENV}
      end
    
      it "can generate an env_variable_string which is passed through sudo to chef-solo" do
        ENV["FOO"]="BAR"
        ENV["FAZ"]="FUZ"
        @generator.stub!(:preserved_environment_variables).and_return(["FOO", "FAZ"])
        @generator.preserved_environment_variables_string.should == "FOO=BAR FAZ=FUZ"
      end
      
      it "adds any environment variables that are switched in the config" do
      @config = <<-CONFIG
cookbook_paths:
- ./chef/cookbooks/
recipes:
- pivotal_workstation::ack
env_variable_switches:
  ME_TOO:
    development:
      cookbook_paths:
      - ./chef/dev_cookbooks/
      recipes:
      - pivotal_dev::foo
      CONFIG
        @generator = Soloist::ChefConfigGenerator.new(YAML.load(@config), "")
        @generator.preserved_environment_variables.should =~ %w{PATH BUNDLE_PATH GEM_HOME GEM_PATH RAILS_ENV RACK_ENV ME_TOO}
      end
    end
  end
  
  describe "yaml config values" do
    before do
      FileUtils.stub(:pwd).and_return("/")
    end
      
    it "accepts Cookbook_Paths, because the CamelSnake is a typo that must be supported" do
      @config = "Cookbook_Paths:\n- ./chef/cookbooks/\n"
      @generator = Soloist::ChefConfigGenerator.new(YAML.load(@config), "..")
      @generator.cookbook_paths.should == ["//.././chef/cookbooks/"]
    end
    
    it "accepts cookbook_paths, because it is sane" do
      @config = "cookbook_paths:\n- ./chef/cookbooks/\n"
      @generator = Soloist::ChefConfigGenerator.new(YAML.load(@config), "..")
      @generator.cookbook_paths.should == ["//.././chef/cookbooks/"]
    end
    
    it "accepts Recipes, because that's the way it was" do
      @config = "Recipes:\n- pivotal_workstation::ack"
      @generator = Soloist::ChefConfigGenerator.new(YAML.load(@config), "")
      @generator.json_hash.should == { "recipes" => ["pivotal_workstation::ack"]}
    end

    it "accepts recipes, because it's snake now" do
      @config = "recipes:\n- pivotal_workstation::ack"
      @generator = Soloist::ChefConfigGenerator.new(YAML.load(@config), "")
      @generator.json_hash.should == { "recipes" => ["pivotal_workstation::ack"]}
    end
    
    it "should set node attributes" do
      @config = "node_attributes:\n  github_username: avh4"
      @generator = Soloist::ChefConfigGenerator.new(YAML.load(@config), "")
      @generator.json_hash.should == { "recipes" => [], "github_username" => "avh4" }
    end
  end
  
  describe "environment variable merging" do
    before do
      FileUtils.stub(:pwd).and_return("/")
    end

    it "merges in if the variable is set to the the value" do
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
      ENV["RACK_ENV"]="development"
      @generator = Soloist::ChefConfigGenerator.new(YAML.load(@config), "../..")
      @generator.cookbook_paths.should == [
        "//../.././chef/cookbooks/",
        "//../.././chef/dev_cookbooks/"
        ]
      @generator.json_hash["recipes"].should == [
        "pivotal_workstation::ack", 
        "pivotal_dev::foo"
        ]
    end
    
    it "merges cookbook_gems" do
      @config = <<-CONFIG
      cookbook_gems:
      - pivotal_shared
      env_variable_switches:
        RACK_ENV:
          development:
            cookbook_gems:
            - pivotal_shared
            - pivotal_workstation
            CONFIG
      @generator = Soloist::ChefConfigGenerator.new(YAML.load(@config), "../..")
      @generator.cookbook_gems.should =~ [
        "pivotal_shared",
        "pivotal_workstation"
        ]
    end
    
    it "splits the value on comma and applies all matching" do
      ENV["ROLES"]="application,database"
      @config = <<-CONFIG
cookbook_paths:
- ./chef/cookbooks/
recipes:
- pivotal_workstation::ack
env_variable_switches:
  ROLES:
    application:
      cookbook_paths:
      - ./chef/app_cookbooks/
      recipes:
      - pivotal_app::application
    database:
      cookbook_paths:
      - ./chef/db_cookbooks/
      recipes:
      - pivotal_db::database
      CONFIG
      @generator = Soloist::ChefConfigGenerator.new(YAML.load(@config), "../..")
      @generator.cookbook_paths.should =~ [
        "//../.././chef/cookbooks/",
        "//../.././chef/app_cookbooks/",
        "//../.././chef/db_cookbooks/"
        ]
      @generator.json_hash["recipes"].should =~ [
        "pivotal_workstation::ack", 
        "pivotal_app::application",
        "pivotal_db::database",
        ]
    end
    
    it "can deal with empty env switched variables, and passes them through" do
      config = <<-CONFIG
env_variable_switches:
  RACK_ENV:
      CONFIG
      @generator = Soloist::ChefConfigGenerator.new(YAML.load(config), "../..")
      @generator.preserved_environment_variables.should include("RACK_ENV")
    end


    it "can deal with only having environment switched recipes/cookbooks" do
      config = <<-CONFIG
env_variable_switches:
  RACK_ENV:
    development:
      cookbook_paths:
      - ./chef/development_cookbooks/
      recipes:
      - pivotal_development::foo
      CONFIG
      @generator = Soloist::ChefConfigGenerator.new(YAML.load(config), "../..")
      @generator.cookbook_paths.should == [
        "//../.././chef/development_cookbooks/"
        ]
      @generator.json_hash["recipes"].should == [
        "pivotal_development::foo"
        ]
    end
    it "can deal with only having empty recipes/cookbooks" do
      config = <<-CONFIG
cookbook_paths:
recipes:
env_variable_switches:
  RACK_ENV:
    development:
      cookbook_paths:
      - ./chef/development_cookbooks/
      recipes:
      - pivotal_development::foo
      CONFIG
      @generator = Soloist::ChefConfigGenerator.new(YAML.load(config), "../..")
      @generator.cookbook_paths.should == [
        "//../.././chef/development_cookbooks/"
        ]
      @generator.json_hash["recipes"].should == [
        "pivotal_development::foo"
        ]
    end
  end
end
