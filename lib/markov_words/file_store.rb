require 'securerandom'

module MarkovWords
  # Utility for persisting arbitrary data to disk as Marshal'ed Ruby objects
  class FileStore
    attr_reader :file_path
    attr_reader :data

    # @option opts [String] :file_path Path and name for where the file should
    #   be stored.
    # @option opts [Boolean] :flush_data Do you want the file to be cleared on
    #   open?
    def initialize(opts)
      @file_path = opts.fetch :file_path, "/tmp/#{SecureRandom.base64}"
      delete_if_exists(@file_path) if opts[:flush_data]
    end

    # Store arbitary data into file storage
    # @param data [Object] Any Marshal-able object
    def store_data(data)
      File.open(@file_path, 'wb') { |f| Marshal.dump(data, f) }
    end

    # Retrieve whatever data is stored in the file + return it
    def retrieve_data
      result = nil
      if File.exist?(@file_path)
        File.open(@file_path, 'r') { |f| result = Marshal.load(f) }
      end
      result
    end

    private

    def delete_if_exists(path)
      File.delete path if File.exist? path
    end
  end
end
