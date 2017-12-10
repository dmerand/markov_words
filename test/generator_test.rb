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
    words = get_words
    assert words.word
  end

  def test_minimum_word_length
    min_length = 5
    words = get_words(min_length: min_length)
    num_iterations.times do
      word = words.word
      assert word.length >= min_length,
             %(word: "#{word}" is #{word.length} long,) +
             " should be >= #{min_length}."
    end
  end

  def test_maximum_word_length
    max_length = 5
    words = get_words(max_length: max_length)
    num_iterations.times do
      word = words.word
      assert word.length <= max_length,
             %(word: "#{word}" is #{word.length} long,) +
             " should be <= #{max_length}."
    end
  end

  def test_changing_gram_size_still_returns_words
    words = get_words(gram_size: 2)
    assert words.word
  end

  private

  def clear_test_data_files
    filename = 'tmp/test.data'
    File.delete(filename) if File.exist?(filename)
  end

  # Keep the n-gram size down for testing, because computation is faster that
  # way. We also don't want caching by default (that gets tested specifically).
  def get_words(opts = {})
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
