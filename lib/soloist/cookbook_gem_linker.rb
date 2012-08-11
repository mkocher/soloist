class CookbookGemLinker
  include Soloist::Util
  attr_reader :gems_and_dependencies
  def initialize(gems=[])
    @gems = gems
  end

  def link_gem_cookbooks
    gems_and_dependencies.each do |gem_cookbook|
      link_cookbook(gem_cookbook)
    end
  end

  def gems_and_dependencies
    unless @gems_and_dependencies
      @gems_and_dependencies = Set.new
      calculate_gems_and_dependencies
    end
    @gems_and_dependencies
  end

  def cookbook_gem_temp_dir
    @cookbook_gem_temp_dir ||= Dir.mktmpdir
  end

  def path_to(gem_name)
    require gem_name
    path = Kernel.const_get(camelize(gem_name)).const_get('COOKBOOK_PATH')
  end

  def link_cookbook(gem_name)
    File.symlink(path_to(gem_name), File.join(cookbook_gem_temp_dir, gem_name.chomp("_cookbook")))
  end

  private

  def calculate_gems_and_dependencies(gems=@gems)
    gems.each do |gem_cookbook|
      @gems_and_dependencies.add(gem_cookbook)
      Gem::Specification.find_by_name(gem_cookbook).dependencies.map(&:name).each do |depdency|
        @gems_and_dependencies.add(depdency)
        calculate_gems_and_dependencies([depdency])
      end
    end
  end
end