# frozen-string-literal: true

module MarkovWords
  # This class takes care of word generation, caching, and data storage.
  class Generator
    # The current list of cached words.
    # @return [Array<String>] All words in the cache.
    def cache
      @data_store.retrieve_data(:cache)
    end

    # The current database of n-gram mappings
    # @return [Hash] n-gram database
    def grams
      @grams = @grams ||
               @data_store.retrieve_data(:grams) ||
               markov_corpus(@corpus_file, @gram_size)
    end

    # Create a new "Words" object
    # @param opts [Hash]
    # @option opts [Integer] :cache_size How many words to pre-calculate +
    #   store in the cache for quick retrieval
    # @option opts [String] :corpus_file ('/usr/share/dict/words') Your
    #   dictionary of words.
    # @option opts [String] :data_file Location where calculations are
    #   persisted to disk.
    # @option opts [String] :flush_data Remove any previously-stored data from
    #   an existing database file.
    # @option opts [Integer] :gram_size (2) Number of n-grams to compute for
    #   your database.
    # @option opts [Integer] :max_length (16) Max generated word length.
    # @option opts [Integer] :min_length (3) Minimum generated word length.
    #   NOTE: If your corpus size is very small (<1000 words or so), it's hard
    #   to guarantee a min_length because so many n-grams will have no
    #   association, which terminates word generation.
    # @option opts [Boolean] :perform_caching (true) Perform caching?
    # @return [Words] A `MarkovWords::Generator` object.
    def initialize(opts = {})
      @grams = nil
      @gram_size = opts.fetch :gram_size, 2
      @max_length = opts.fetch :max_length, 16
      @min_length = opts.fetch :min_length, 3

      initialize_cache(opts)
      initialize_data(opts)
    end

    # "Top off" the cache of stored words, and ensure that it's at
    # `@cache_size`. If `perform_caching` is set to `false`, returns an empty
    # array.
    # @return [Array<String>] All words in the cache.
    def refresh_cache
      if @perform_caching
        words_array = @data_store.retrieve_data(:cache) || []
        words_array << generate_word while words_array.length < @cache_size
        @data_store.store_data(:cache, words_array)
        words_array
      else
        []
      end
    end

    # Generate a new word, or return one from the cache if available.
    # @return [String] The word.
    def word
      if @perform_caching
        load_word_from_cache
      else
        generate_word
      end
    end

    private

    def contains_vowel?(ary)
      if ary.length < 2
        true
      else
        ary.take(2).join.match(/[aeiou]/)
      end
    end

    def initialize_cache(opts)
      @cache_size = opts.fetch :cache_size, 100
      @perform_caching = opts.fetch :perform_caching, true
    end

    def initialize_data(opts)
      @corpus_file = opts.fetch :corpus_file, '/usr/share/dict/words'
      @data_file = opts.fetch :data_file, 'tmp/markov_words.data'
      @flush_data = opts.fetch :flush_data, false
      @data_store = FileStore.new file_path: @data_file,
                                  flush_data: @flush_data
    end

    def generate_word
      generate_gram_array(generate_word_length).join
    end

    def generate_gram_array(desired_length)
      gram = ''
      gram_array = generate_initial_gram_array
      until gram_array.join.length == desired_length || gram.nil?
        # grab last @gram_size (or possibly fewer if the array is too small)
        # elements from the current gram_array, to use as the next key.
        gal = gram_array.length
        current_gram_size = gal >= @gram_size ? @gram_size : gal
        key = gram_array[-current_gram_size..-1].join

        gram = pick_random_char(grams[key])
        gram_array << gram
      end
      gram_array
    end

    def generate_initial_gram_array
      initial_gram_array = []

      all_grams_array = grams.to_a
      gram_min_length = @gram_size < @min_length ? @gram_size : @min_length
      until initial_gram_array.length >= gram_min_length &&
            contains_vowel?(initial_gram_array)
        initial_gram_array = all_grams_array.sample[0].chars
      end
      initial_gram_array
    end

    def generate_word_length
      word_length = 0
      until word_length >= @min_length
        word_length = SecureRandom.rand(@max_length)
      end
      word_length
    end

    def line_ending?(word)
      /[\r\n]/.match? word
    end

    def load_word_from_cache
      words_array = @data_store.retrieve_data(:cache)
      if words_array.nil? || words_array.empty?
        words_array = Array.new(@cache_size) { generate_word }
      end

      word = words_array.pop
      @data_store.store_data(:cache, words_array)

      word
    end

    # Generate a MarkovWords corpus from a datafile, with a given size of
    # n-gram.  Returns a hash of "grams", which are a map of a letter to the
    # frequency of the letters that follow it, eg: {"c" => {"a" => 1, "b" =>
    # 2}}
    def markov_corpus(file, gram_size)
      grams = {}

      # Corpus contains a list of words, separated by newlines
      File.foreach(file) do |word|
        word = word.downcase.delete('-')
        gram_size.downto(1) do |current_gram_size|
          markov_update_count! grams, word, current_gram_size
        end
      end

      grams
    end

    # Given a database of `grams` and a `word`, and the `gram_size` (the
    # maximum n-gram size we want to compute), update the `grams` database with
    # entries for each n-gram combination starting at `gram_size` and going
    # down to 1.
    def markov_update_count!(grams, word, gram_size)
      word.chars.each_cons(gram_size + 1) do |gram|
        l = gram[0..gram_size - 1].join
        r = gram[gram_size]

        unless l.empty? || r.empty? || line_ending?(r)
          grams[l] = {} if grams[l].nil?
          grams[l][r] = grams[l][r].nil? ? 1 : grams[l][r] += 1
        end
      end
    end

    # Given a hash in the format: {"c" => {"a" => 1, "b" => 2}}, grab a random
    # element from the values hash, accurate to the distribution of counts.
    # In the example hash above, "a" would have a 33% chance of being chosen,
    # while "b" would have a 66% chance (1/2 ratio).
    def pick_random_char(counts_hash)
      return nil if counts_hash.nil?
      total = counts_hash.values.sum
      pick_num = SecureRandom.rand(total)
      counter = 0
      counts_hash.each do |char, count|
        counter += count
        return char if counter >= pick_num
      end
    end
  end
end
