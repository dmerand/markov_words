require 'test_helper'
require 'markov_words/file_store'

class FileStoreTest < Minitest::Test

  def test_data_retrieval
    file_store = set_file_store
    file_store.store_data(test_data)
    assert_equal file_store.retrieve_data, test_data

    cleanup(file_store)
  end

  def test_stores_to_passed_file
    file_path = 'tmp/test_custom_file_path.test'
    file_store = set_file_store(file_path: file_path)
    file_store.store_data(test_data)

    assert File.exist? file_path

    cleanup(file_store)
  end

  def test_flush_file
    fs_one = set_file_store
    fs_one.store_data test_data
    # now we have data in the file
    fs_two = set_file_store(flush_data: true)
    assert_nil fs_two.retrieve_data

    cleanup(fs_one)
    cleanup(fs_two)
  end

  private

  def cleanup(file_store)
    if File.exist? file_store.file_path
      File.delete file_store.file_path
    end
  end

  # Keep the n-gram size down for testing, because computation is faster that
  # way. We also don't want caching by default (that gets tested specifically).
  def set_file_store(opts = {})
    MarkovWords::FileStore.new({
      file_path: 'tmp/file_storage.test',
    }.merge(opts))
  end

  def test_data
    {cool: 'beans'}
  end

end
