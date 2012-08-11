require 'rubygems'
require "json"
require 'fileutils'
require 'yaml'
require 'tempfile'
require 'tmpdir'
require 'set'

require File.join(File.dirname(__FILE__), 'soloist', 'util')
require File.join(File.dirname(__FILE__), 'soloist', 'chef_config_generator')
require File.join(File.dirname(__FILE__), 'soloist', 'cookbook_gem_linker')