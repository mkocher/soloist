Soloist: Making chef-solo easier
================================

# Why?
You just want to use chef solo, not worry about where your config files are, or what they should look like (too much).  You might think that json is a data serialization format and not a config file format.  You might think that having two config files that you have to pass to an executable every time you run it is two too many.

# How?
Soloist is a script packaged as a gem which when run recurses up the file tree looking for a soloistrc file.  When it finds it, it uses it to determine 1) Where its cookbooks are and 2) What recipes to run.  It generates the necessary config files for chef solo, and kicks it off.

# That's exactly what I've always wanted! How do I use it?
* (sudo) gem install soloist
* create a directory to store your cookbooks in, and get a cookbook: 
	bash sh -c 'mkdir -p chef/pivotal_workstation && cd chef/pivotal_workstation &&  curl -L http://github.com/mkocher/pivotal_workstation/tarball/master |  gunzip | tar xvf - --strip=1'
* create your soloistrc file in the root of your project.

# What if I'm just setting up my own machine, and have many projects?
Just put your soloistrc file in your home directory, and point it to wherever you want to keep your cookbooks. Or just dedicate a git repo to it, and go into that directory before running soloist.

# How do I write a solistrc file?
It's a yaml file, currently with two lists to maintain:

The first, _Cookbook\_Paths_, should point (using an absolute or path relative to your soloistrc file) to the directory containing your cookbooks, such was pivotal_workstation.

The second, _Recipes_ should be a list of recipes you wish to run.

# Then What?
$> soloist


Example soloistrc Files
=======================

directory layout:

    /Users/mkocher/workspace/project/soloistrc <-Config File
    /Users/mkocher/workspace/project/chef/
    /Users/mkocher/workspace/project/chef/cookbooks/pivotal_workstation/


soloistrc
---------
  	Cookbook_Paths:
  	- ./chef/cookbooks/
  	Recipes:
  	- pivotal_workstation::text_mate
  	- pivotal_workstation::git
  	- pivotal_workstation::git_config_global_defaults
  	- pivotal_workstation::bash_profile-better_history
  	- pivotal_workstation::bash_path_order
  	- pivotal_workstation::bash_profile
  	- pivotal_workstation::finder_display_full_path
  	- pivotal_workstation::git_config_global_defaults
  	- pivotal_workstation::inputrc
  	- pivotal_workstation::osx_turn_on_locate
  	- pivotal_workstation::textmate_set_defaults
  	- pivotal_workstation::rvm
  	- pivotal_workstation::mysql
  	- pivotal_workstation::defaults_fast_key_repeat_rate
  	- pivotal_workstation::ec2_api_tools