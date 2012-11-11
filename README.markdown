# Soloist

[![Build Status](https://secure.travis-ci.org/mkocher/soloist.png)](http://travis-ci.org/mkocher/soloist)

A Brief History
---------------

Traditionally, using `chef-solo` meant hand-rolling `solo.rb` and some `node.json` file.  Then, you run `chef-solo -c solo.rb -j node.json` and remember, yet again, that you need to prefix the whole thing with `sudo`.

Meanwhile, back in the modern world, tools like Bundler and Vagrant have one authoritative file for their configuration data.  Soloist attempts to rectify this situation.

Prerequisites
-------------

1. You'll need a `Cheffile` that points [Librarian](https://github.com/applicationsonline/librarian) to all the cookbooks you've included.  Check out their documentation about how to create one.  It looks like this:

        site "http://community.opscode.com/api/v1"
        cookbook "pivotal_workstation",
                 :git => "https://github.com/pivotal/pivotal_workstation"

2. You'll need to create a `soloistrc` file.  It looks like this:

        recipes:
          - pivotal_workstation::default
          - pivotal_workstation::sublime_text

How does Soloist work?
----------------------

Soloist searches for a `soloistrc` file in your working directory.  If it can't find one, it searches all the parent directories.  Then it looks for a `Cheffile` in that same directory.  Then, it tells `chef-solo` to look in the `cookbooks` path relative to the `soloistrc` directory, as well as what recipes to install.

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

##### Running one-off recipes

Soloist can also run one-off recipes:

    $ soloist install lice::box
    Installing lice (1.0.0)
    … chef output …
    INFO: Run List expands to [lice::box]
    … chef output …

##### Conditionally running a set of recipes

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

##### Setting node attributes

Soloist lets you override node attributes.  Let's say we've got a `bash::prompt` recipe for which  we want to set `node['bash']['prompt']['color']='p!nk'`.  No problem!

    recipes:
      - bash::prompt
    node_attributes:
      bash:
        prompt:
          color: p!nk

Log Level
---------

Soloist runs chef at log level info by default.  Debug is very verbose, but makes debugging chef recipes much easier.  Just set the LOG_LEVEL environment variable to 'debug' (or other valid chef log level) and it will be passed through.

License
=======
Soloist is MIT Licensed.  See MIT-LICENSE for details.
