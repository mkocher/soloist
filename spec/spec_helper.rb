$: << File.expand_path("../../lib", __FILE__)

require "soloist"
require "tempfile"
require "json"
require "tmpdir"
require "net/ssh/test"

Dir.glob(File.expand_path("../helpers/**/*.rb", __FILE__)) { |f| require f }

RSpec.configure do |config|
  config.add_setting :tempdir
  config.before(:each) { RSpec.configuration.tempdir = Dir.mktmpdir }
  config.after(:each) { FileUtils.rm_rf(RSpec.configuration.tempdir) }
  config.expose_dsl_globally = false
end
