require 'spec_helper'

describe CookbookGemLinker do
  let(:linker) { CookbookGemLinker.new(["pivotal_workstation_cookbook"]) }

  describe ".cookbook_gem_temp_dir" do
    it "returns a tmpdir" do
      Dir.should_receive(:mktmpdir).once.and_return("/tmp/foo")
      2.times { linker.cookbook_gem_temp_dir.should == "/tmp/foo" }
    end
  end

  describe ".path_to" do
    it "returns the path to the gem" do
      linker.path_to("pivotal_workstation_cookbook").should == File.expand_path('../..', __FILE__)
    end
  end

  describe ".link_cookbook" do
    it "creates a symbolic link in the tempdir" do
      linker.link_cookbook("pivotal_workstation_cookbook")
      File.exist?(File.expand_path('pivotal_workstation', linker.cookbook_gem_temp_dir)).should be
    end
  end

  describe '.gems_and_dependencies' do
    it "returns what you pass in dependencies" do
      mock_gem("pivotal_workstation_cookbook")

      linker.gems_and_dependencies.to_a.should == ["pivotal_workstation_cookbook"]
    end

    it "gets the dependencies from rubygems" do
      mock_gem("pivotal_workstation_cookbook", ['osx_dmg_cookbook'])
      mock_gem("osx_dmg_cookbook")

      linker.gems_and_dependencies.to_a.should == ["pivotal_workstation_cookbook", 'osx_dmg_cookbook']
    end

    it "gets dependencies for dependencies" do
      mock_gem("pivotal_workstation_cookbook", ['osx_dmg_cookbook'])
      mock_gem("osx_dmg_cookbook", ["osx_installer_thing"])
      mock_gem("osx_installer_thing")

      linker.gems_and_dependencies.to_a.should == ["pivotal_workstation_cookbook", 'osx_dmg_cookbook', 'osx_installer_thing']
    end
  end

  describe ".link_gem_cookbooks" do
    it "creates a directory of symlinks" do
      mock_gem("pivotal_workstation_cookbook")
      linker.link_gem_cookbooks
      File.exist?(File.expand_path('pivotal_workstation', linker.cookbook_gem_temp_dir)).should be
    end
  end
end