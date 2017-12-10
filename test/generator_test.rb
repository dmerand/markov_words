# frozen-string-literal: true

require 'test_helper'

class GeneratorTest < Minitest::Test
  # We need to ensure that any stored data is toasted between tests.
  def setup
    clear_test_data_files
  end

  def teardown
    clear_test_data_files
  end

  def test_that_it_has_a_version_number
    refute_nil ::MarkovWords::VERSION
  end

  def test_returns_a_word
    generator = get_generator
    assert generator.word
  end

  def test_minimum_word_length
    min_length = 5
    generator = get_generator(min_length: min_length)
    num_iterations.times do
      word = generator.word
      assert word.length >= min_length,
             %(word: "#{word}" is #{word.length} long,) +
             " should be >= #{min_length}."
    end
  end

  def test_maximum_word_length
    max_length = 5
    generator = get_generator(max_length: max_length)
    num_iterations.times do
      word = generator.word
      assert word.length <= max_length,
             %(word: "#{word}" is #{word.length} long,) +
             " should be <= #{max_length}."
    end
  end

  def test_changing_gram_size_still_returns_words
    generator = get_generator(gram_size: 2)
    assert generator.word
  end

  def test_setting_and_retrieving_from_data_store
    generator = get_generator
    test_data = { cool: 'beans' }
    generator.data_store.store_data :test, test_data
    assert_equal generator.data_store.retrieve_data(:test), test_data
  end

  private

  def clear_test_data_files
    filename = 'tmp/test.data'
    File.delete(filename) if File.exist?(filename)
  end

  # Keep the n-gram size down for testing, because computation is faster that
  # way. We also don't want caching by default (that gets tested specifically).
  def get_generator(opts = {})
    MarkovWords::Generator.new({
      corpus_file: 'test/dictionary',
      data_file: 'tmp/test.data',
      gram_size: 1,
      perform_caching: false
    }.merge(opts))
  end

  def num_iterations
    100
  end
end
