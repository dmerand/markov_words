# frozen-string-literal: true

require 'test_helper'
require 'markov_words/file_store'

class FileStoreTest < Minitest::Test
  def test_data_retrieval
    file_store = get_file_store
    file_store.store_data key, data
    assert_equal file_store.retrieve_data(key), data

    cleanup
  end

  def test_stores_to_passed_file
    file_path = 'tmp/test_custom_file_path.test'
    file_store = get_file_store(file_path: file_path)
    file_store.store_data(key, data)

    assert File.exist? file_path

    cleanup file_path
  end

  def test_flush_file
    fs_one = get_file_store
    fs_one.store_data key, data
    # now we have data in the file
    fs_two = get_file_store(flush_data: true)
    assert_nil fs_two.retrieve_data

    cleanup
    cleanup
  end

  private

  def cleanup(file_path = default_path)
    File.delete(file_path) if File.exist?(file_path)
  end

  def default_path
    'tmp/storage_test.db'
  end

  # Keep the n-gram size down for testing, because computation is faster that
  # way. We also don't want caching by default (that gets tested specifically).
  def get_file_store(opts = {})
    MarkovWords::FileStore.new({
      file_path: default_path
    }.merge(opts))
  end

  def data
    { cool: 'beans' }
  end

  def key
    :test
  end
end
