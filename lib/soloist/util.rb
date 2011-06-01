module Soloist
  class Util
    def self.fileify(contents)
      file = Tempfile.new("soloist")
      file << contents
      file.flush
      file
    end
    
    def self.walk_up_and_find_file(filenames, opts={})
      pwd = FileUtils.pwd
      file = nil
      path_to_file = ""
      while !file && FileUtils.pwd != '/'
        file = filenames.detect { |f| File.exists?(f) }
        FileUtils.cd("..")
        path_to_file << "../" unless file
      end
      FileUtils.cd(pwd)
      if file
        file_contents = File.read(path_to_file + file) if file
        [file_contents, path_to_file]
      elsif opts[:required] == false
        [nil, nil]
      else
        raise Errno::ENOENT, "#{filenames.join(" or ")} not found" unless file || opts[:required] == false
      end
    end
  end
end