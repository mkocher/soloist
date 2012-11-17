$: << File.expand_path("../../lib", __FILE__)

require "soloist"
require "tempfile"
require "json"
require "tmpdir"
require "net/ssh/test"

Dir.glob(File.expand_path("../helpers/**/*.rb", __FILE__)) { |f| require f }
