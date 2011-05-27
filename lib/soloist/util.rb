module Soloist
  class Util
    def self.fileify(contents)
      file = Tempfile.new("soloist")
      file << contents
      file.flush
      file
    end
    
    def self.walk_up_and_find_file(filenames)
      pwd = FileUtils.pwd
      file = nil
      path_to_file = ""
      while !file && FileUtils.pwd != '/'
        file = filenames.detect { |f| Dir.glob("*").include?(f) }
        FileUtils.cd("..")
        path_to_file << "../" unless file
      end
      FileUtils.cd(pwd)
      raise Errno::ENOENT, "#{filenames} not found" unless file
      file_contents = File.read(path_to_file + file)# if file
      [file_contents, path_to_file]
    end
  end
end