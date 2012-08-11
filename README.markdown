Soloist: Making chef-solo easier
================================

# Why?
You just want to use chef solo, not worry about where your config files are, or what they should look like (too much).  You might think that json is a data serialization format and not a config file format.  You might think that having two config files that you have to pass to an executable every time you run it is two too many.

# How?
Soloist is a script packaged as a gem which when run recurses up the file tree looking for a soloistrc file.  When it finds it, it uses it to determine 1) Where its cookbooks are and 2) What recipes to run.  It generates the necessary config files for chef solo, and kicks it off.

# That's exactly what I've always wanted! How do I use it?
* (sudo) gem install soloist
* create a directory to store your cookbooks in, and get a cookbook: 
	sh -c 'mkdir -p chef/cookbooks/pivotal_workstation && cd chef/cookbooks/pivotal_workstation &&  curl -L http://github.com/pivotal/pivotal_workstation/tarball/master |  gunzip | tar xvf - --strip=1'
* create your soloistrc file in the root of your project.

# What if I'm just setting up my own machine, and have many projects?
Just put your soloistrc file in your home directory, and point it to wherever you want to keep your cookbooks. Or just dedicate a git repo to it, and go into that directory before running soloist.

# How do I write a soloistrc file?
It's a yaml file, currently with two lists to maintain:

The first, _cookbook\_paths_, should point (using an absolute or path relative to your soloistrc file) to the directory containing your cookbooks, such was pivotal_workstation.

The second, _recipes_ should be a list of recipes you wish to run.

# Then What?
$> soloist


Example soloistrc Files
=======================

directory layout:

    /Users/mkocher/workspace/project/soloistrc <-Config File
    /Users/mkocher/workspace/project/cookbooks/pivotal_workstation/


soloistrc
---------
	cookbook_paths:
	- ./cookbooks/
	recipes:
	- pivotal_workstation::ack
	- pivotal_workstation::bash_path_order
	- pivotal_workstation::bash_profile-better_history
	- pivotal_workstation::defaults_fast_key_repeat_rate
	- pivotal_workstation::finder_display_full_path
	- pivotal_workstation::git_config_global_defaults
	- pivotal_workstation::git_scripts
	- pivotal_workstation::google_chrome
	- pivotal_workstation::inputrc
	- pivotal_workstation::rvm
	- pivotal_workstation::turn_on_ssh

Packaging Gems as Cookbooks (alpha)
===========================

If you're a ruby developer, you're probably very comfortable wrangling gems.  Bundler makes it easy to lock your dependencies and keep them in sync in all your environments.  Soloist adds the ability to load cookbooks out of these gems.  This means you can install the  pivotal_workstation_cookbook gem, and add it to your soloistrc like so:

	cookbook_gems:
	- pivotal_workstation_cookbook

Easy cookbook dependency tracking, no more git cloning, no more chef recipes that aren't yours checked into your project and easy forking with bundler and github.

Environment Variable Switching
==============================
The soloistrc file allows for selecting all options based on environment variables.  Cap should allow setting environment variables fairly easily on deploy, and they can be set permanently on the machine if desired.  To use these, add a env_variable_switches key to your soloistrc.  They keys of the hash should be the environment variable you wish to change the configuration based on, and the value should be a hash keyed by the value of the variable.  It's easier than it sounds - see the example below.

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
	
Log Level
=========
Soloist runs chef at log level info by default.  Debug is very verbose, but makes debugging chef recipes much easier.  Just set the LOG_LEVEL environment variable to 'debug' (or other valid chef log level) and it will be passed through.

Local Overrides
==============================
Soloist is an easy way to share configuration across workstations.  If you want to have configuration in chef that you don't want to share with the rest of the project, you can create a soloistrc_local file in addition to the soloistrc file.  This file will be processed after the soloistrc, and everything in it will be added to the run list.  Be careful that you are clear what goes where - if it's a dependency of the project, it should be checked into the soloistrc file in the project.

Setting Node Attributes
=======================
You can set node attributes in your soloistrc file that will be included in the JSON attributes file passed to chef-solo.

    cookbook_paths:
    - ./chef/cookbooks/
    recipes:
    - pivotal_workstation::github_ssh_keys
    - pivotal_workstation::rvm
    node_attributes:
      github_username: john.smith
      github_password: pas$w0rd
      rvm:
        rubies:
          ruby-1.8.7-p299: {}
          jruby-1.6.6: {}

License
=======
Soloist is MIT Licensed.  See MIT-LICENSE for details.