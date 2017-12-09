# frozen-string-literal: true

require 'securerandom'
require 'sqlite3'

module MarkovWords
  # Utility for persisting arbitrary data to disk.
  class FileStore
    # @option opts [String] :file_path Path and name for where the file should
    #   be stored.
    # @option opts [Boolean] :flush_data Do you want the file to be cleared on
    #   open?
    def initialize(opts)
      @file_path = opts.fetch :file_path, "/tmp/#{SecureRandom.base64}"
      initialize_db
      empty_db if opts[:flush_data]
    end

    # Store arbitary data, named with a `key`
    # @param key [Symbol] Unique key for later data retrieval
    # @param data [Object] Any Marshal-able object
    def store_data(key = :discard, data = nil)
      key = key.to_s unless key.is_a? String
      if data_exists(key)
        @db.execute 'UPDATE data SET value = ? WHERE key = ?',
                    [Marshal.dump(data), key]
      else
        @db.execute 'INSERT INTO data VALUES ( ?, ? )',
                    [key, Marshal.dump(data)]
      end
    end

    # Retrieve whatever data is stored in at `key`, and return it!
    def retrieve_data(key = '')
      key = key.to_s unless key.is_a? String
      data_array = @db.execute 'SELECT value FROM data WHERE key = ?', key
      Marshal.load(data_array[0][0]) unless data_array[0].nil?
    end

    private

    def create_initial_tables
      @db.execute <<~SQL
        create table data (
          key varchar(5),
          value binary
        );
      SQL
    end

    def data_exists(key)
      query = 'SELECT count(*) FROM data WHERE key = ?'
      @db.execute(query, key)[0][0].positive?
    end

    def empty_db
      @db.execute 'delete from data'
    end

    def initialize_db
      @db = SQLite3::Database.new @file_path
      table = @db.execute("SELECT name FROM sqlite_master
                          WHERE type='table'
                          AND name='data';").first
      create_initial_tables unless table
    end
  end
end
