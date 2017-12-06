require "test_helper"

class MarkovWordsTest < Minitest::Test
  ITERATIONS = 100

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

  def test_false_cache_has_no_cache_data
    words = set_words(cache: false)
    # Cache won't generate until we ask for a word
    _discard = words.word
    assert_nil words.cache_store.retrieve_data
  end

  def test_cache_size_param
    cache_size = 10
    words = set_words(cache: true, cache_size: cache_size)
    # Cache won't generate until we ask for a word
    _discard = words.word
    assert_equal words.cache_size, cache_size
    assert_equal words.cache_store.retrieve_data.length, cache_size - 1
  end

  def test_cache_refresh
    cache_size = 10
    words = set_words(cache: true, cache_size: cache_size)
    # Cache won't generate until we ask for a word
    (cache_size / 2).times { _discard = words.word }
    words.refresh_cache
    assert_equal words.cache_store.retrieve_data.length, cache_size
  end

  private

  def clear_test_data_files
    %w{data cache}.each do |suffix|
      filename = "tmp/test.#{suffix}"
      File.delete(filename) if File.exist?(filename)
    end
  end

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
