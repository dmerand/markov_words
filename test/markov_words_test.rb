require "test_helper"

class MarkovWordsTest < Minitest::Test
  ITERATIONS = 100

  # We need to ensure that any stored data is toasted between tests.
  def setup
    ['test.cache', 'test.data'].each do |file|
      file = "tmp/#{file}"
      File.delete(file) if File.exist?(file)
    end
  end

  def test_that_it_has_a_version_number
    refute_nil ::MarkovWords::VERSION
  end

  def test_returns_a_word
    words = set_words
    assert words.word
  end

  def test_minimum_word_length
    min_length = 5
    words = set_words(min_length: min_length)
    ITERATIONS.times do
      word = words.word
      assert word.length >= min_length,
        %{word: "#{word}" is #{word.length} long, should be >= #{min_length}.}
    end
  end

  def test_maximum_word_length
    max_length = 5
    words = set_words(max_length: max_length)
    ITERATIONS.times do
      word = words.word
      assert word.length <= max_length,
        %{word: "#{word}" is #{word.length} long, should be <= #{max_length}.}
    end
  end

  def test_changing_gram_size_still_returns_words
    words = set_words(gram_size: 2)
    assert words.word
  end

  private

  # Keep the n-gram size down for testing, because computation is faster that
  # way. We also don't want caching by default (that gets tested specifically).
  def set_words(opts = {})
    MarkovWords::Words.new({
      cache: false,
      corpus_file: 'test/dictionary',
      data_file: 'tmp/test.data',
      cache_file: 'tmp/test.cache',
      gram_size: 1
    }.merge(opts))
  end
end
