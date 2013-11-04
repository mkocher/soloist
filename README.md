# Soloist

[![Build Status](https://secure.travis-ci.org/mkocher/soloist.png)](http://travis-ci.org/mkocher/soloist) [![Code Climate](https://codeclimate.com/github/mkocher/soloist.png)](https://codeclimate.com/github/mkocher/soloist)

Soloist lets you quickly and easily converge [Chef](http://opscode.com/chef) recipes using [chef-solo](http://wiki.opscode.com/display/chef/Chef+Solo).  It does not require a Chef server, but can exploit [community cookbooks](http://community.opscode.com/cookbooks), github-hosted cookbooks and locally-sourced cookbooks through [Librarian](https://github.com/applicationsonline/librarian).

Soloist was originally built to support the [Pivotal Labs Workstation Cookbook](https://github.com/pivotal/pivotal_workstation), now known as [Sprout](https://github.com/pivotal-sprout/sprout).

Using Soloist
-------------

Let's say you want to converge the Pivotal Labs Workstation default recipe and install Sublime Text 2.

1. You'll need to have Soloist installed:

        $ gem install soloist

1. You'll need a `Cheffile` in your home directory that points Librarian to all the cookbooks you've included:

        $ cat /Users/pivotal/Cheffile
        site "http://community.opscode.com/api/v1"
        cookbook "pivotal_workstation",
                 :git => "https://github.com/pivotal/pivotal_workstation"

1. You'll need to create a `soloistrc` file in your home directory to tell Chef which recipes to converge:

        $ cat /Users/pivotal/soloistrc
        recipes:
          - pivotal_workstation::default
          - pivotal_workstation::sublime_text

1. You'll need to run `soloist` for anything to happen:

        $ soloist


Examples
--------

##### Running a set of recipes

Here's an example of a `soloistrc`:

    cookbook_paths:
      - /opt/beans
    recipes:
      - beans::chili
      - beans::food_fight
      - napkins

This tells Soloist to search in both `/opt/beans` and `./cookbooks` (relative to the `soloistrc`) for cookbooks to run.  Then, it attempts to converge the `beans::chili`, `beans::food_fight` and `napkins` recipes.


##### Setting node attributes

Soloist lets you override node attributes.  Let's say we've got a `bash::prompt` recipe for which  we want to set `node['bash']['prompt']['color']='p!nk'`.  No problem!

    recipes:
      - bash::prompt
    node_attributes:
      bash:
        prompt:
          color: p!nk


##### Conditionally modifying Soloist

Soloist allows conditionally switching on environment variables.  Let's say we only want to include the `embarrassment::parental` recipe when the `MEGA_PRODUCTION` environment variable is set to `juggalos`.  Here's the `soloistrc`:

    cookbook_paths:
      - /fresno
    recipes:
      - disaster
    env_variable_switches:
      MEGA_PRODUCTION:
        juggalos:
          recipes:
            - embarrassment::parental

So now, this is the result of our Soloist run:

    $ MEGA_PRODUCTION=juggalos soloist
    Installing disaster (1.0.0)
    Installing embarrassment (1.0.0)
    … chef output …
    INFO: Run List expands to [disaster, embarrassment::parental, faygo]
    … chef output …

If we set `MEGA_PRODUCTION=godspeed`, the `embarrassment::parental` recipe is not converged.


##### Running one-off recipes

Soloist can also run one-off recipes:

    $ soloist run_recipe lice::box
    Installing lice (1.0.0)
    … chef output …
    INFO: Run List expands to [lice::box]
    … chef output …

This just runs the `lice::box` recipe from your current set of cookbooks.  It still uses all the `node_attributes` and `env_variable_switches` logic.


##### Chef logging

Soloist runs `chef-solo` at log level `info` by default, which is helpful when you need to see what your Chef run is doing.  If you need more information, you can set the `LOG_LEVEL` environment variable:

    $ LOG_LEVEL=debug soloist


License
=======

See LICENSE for details.
