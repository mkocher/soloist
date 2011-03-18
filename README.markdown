Soloist: Making chef-solo easier
================================

# Why?
You just want to use chef solo, not worry about where your config files are, or what they should look like (too much).  You might think that json is a data serialization format and not a config file format.  You might think that having two config files that you have to pass to an executable every time you run it is two too many.

# How?
Soloist is a script packaged as a gem which when run recurses up the file tree looking for a soloistrc file.  When it finds it, it uses it to determine 1) Where its cookbooks are and 2) What recipes to run.  It generates the necessary config files for chef solo, and kicks it off.

# That's exactly what I've always wanted! How do I use it?
* (sudo) gem install soloist
* create a directory to store your cookbooks in, and get a cookbook: 
	sh -c 'mkdir -p chef/cookbooks/pivotal_workstation && cd chef/cookbooks/pivotal_workstation &&  curl -L http://github.com/mkocher/pivotal_workstation/tarball/master |  gunzip | tar xvf - --strip=1'
* create your soloistrc file in the root of your project.

# What if I'm just setting up my own machine, and have many projects?
Just put your soloistrc file in your home directory, and point it to wherever you want to keep your cookbooks. Or just dedicate a git repo to it, and go into that directory before running soloist.

# How do I write a solistrc file?
It's a yaml file, currently with two lists to maintain:

The first, _cookbook\_paths_, should point (using an absolute or path relative to your soloistrc file) to the directory containing your cookbooks, such was pivotal_workstation.

The second, _recipes_ should be a list of recipes you wish to run.

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
	cookbook_paths:
	- ./chef/cookbooks/
	recipes:
	- pivotal_workstation::ack
	- pivotal_workstation::bash_path_order
	- pivotal_workstation::bash_profile
	- pivotal_workstation::bash_profile-better_history
	- pivotal_workstation::defaults_fast_key_repeat_rate
	- pivotal_workstation::dock_preferences
	- pivotal_workstation::ec2_api_tools
	- pivotal_workstation::finder_display_full_path
	- pivotal_workstation::git
	- pivotal_workstation::git_config_global_defaults
	- pivotal_workstation::git_scripts
	- pivotal_workstation::google_chrome
	- pivotal_workstation::inputrc
	- pivotal_workstation::mysql
	- pivotal_workstation::osx_turn_on_locate
	- pivotal_workstation::rvm
	- pivotal_workstation::safari_preferences
	- pivotal_workstation::set_multitouch_preferences
	- pivotal_workstation::text_mate
	- pivotal_workstation::textmate_set_defaults
	- pivotal_workstation::turn_on_ssh
	- pivotal_workstation::user_owns_usr_local
	- pivotal_workstation::workspace_directory

Environment Variable Switching (Alpha)
======================================
I'm trying out adding support in the soloistrc file for selecting recipes based on environment variables.  Cap should allow setting environment variables fairly easily on deploy, and they can be set permanently on the machine if desired.  To use these, add a env_variable_switches key to your soloistrc.  They keys of the hash should be the environment variable you wish to change the configuration based on, and the value should be a hash keyed by the value of the variable.  It's easier than it sounds - see the example below. (NB: Note that the CamelSnake is gone in the soloistrc, and while the basic config accepts the old keys, environment variable switching requires snake case keys)

	cookbook_paths:
	- ./chef/cookbooks/
	recipes:
	- pivotal_workstation::ack
	env_variable_switches:
	  RACK_ENV:
	    production:
	      cookbook_paths:
	      - ./chef/production_cookbooks/
	      recipes:
	      - production::foo

The values are merged in, so this results in a cookbook path of
	[
      "./chef/cookbooks/",
      "./chef/production_cookbooks/"
    ]
and a recipe list of
	[
	  "pivotal_workstation::ack", 
	  "production::foo"
	]
	
License
=======
Soloist is MIT Licensed.  See MIT-LICENSE for details.