require 'rspec'
require File.dirname(__FILE__) + '/../lib/soloist'

describe Soloist::Util do
  class TestClass
    extend Soloist::Util
  end
  
  describe "walk_up_and_find_file" do
    it "raises an error when the file isn't found" do
      lambda do
        TestClass.walk_up_and_find_file(["file_not_on_the_filesystem"])
      end.should raise_error(Errno::ENOENT, "No such file or directory - file_not_on_the_filesystem not found")
    end
    
    it "doesn't raise an error if :required => false is passed" do
      TestClass.walk_up_and_find_file(["file_not_on_the_filesystem"], :required => false).should == [nil, nil]
    end
  end
end
