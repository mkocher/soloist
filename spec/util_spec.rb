require 'rspec'
require 'lib/soloist'

describe Soloist::Util do
  describe "walk_up_and_find_file" do
    it "raises an error when the file isn't found" do
      lambda do
        Soloist::Util.walk_up_and_find_file("file_not_on_the_filesystem")
      end.should raise_error(Errno::ENOENT, "No such file or directory - file_not_on_the_filesystem not found")
    end
  end
end