module MarkovWords
  # This class takes care of word generation, caching, and data storage.
  class Words
    # Perform caching? Defaults to true.
    attr_reader :cache
    # File location where you want to store the cache
    attr_reader :cache_file
    # How many words you want to store in the cache?
    attr_reader :cache_size
    # Object for storing + retrieving cache data from persistent storage
    attr_reader :cache_store
    # Your dictionary of words. Defaults to /usr/share/dict/words.
    attr_reader :corpus_file
    # Where should your database be stored on disk?
    attr_reader :data_file
    # Object for storing + retrieving n-gram data from persistent storage
    attr_reader :data_store
    # The database of "grams" (word/count combinations), stored on the disk and
    # loaded into this variable in memory when generating words.
    attr_reader :grams
    # Number of n-grams to compute for your database. Defaults to 2
    attr_reader :gram_size
    # Max generated word length. Defaults to 16
    attr_reader :max_length
    # Minimum generated word length. Defaults to 3. NOTE: If your corpus size
    # is very small (<1000 words or so), it's hard to guarantee a min_length
    # because so many n-grams will have no association, which terminates word
    # generation.
    attr_reader :min_length

    # Create a new "Words" object
    # @param opts [Hash] options sent to the object. Any of the object
    #   attributes (eg `:cache_file` or `:gram_size`) are valid parameters to
    #   add to the `opts` hash.
    # @return [Words] A `MarkovWords::Words` object.
    def initialize(opts = {})
      @grams = nil
      @gram_size = opts.fetch :gram_size, 2
      @max_length = opts.fetch :max_length, 16
      @min_length = opts.fetch :min_length, 3

      initialize_cache(opts)
      initialize_data(opts)
    end

    # "Top off" the cache of stored words, and ensure that it's at
    # `@cache_size`. If `@cache` is set to `false`, returns an empty array.
    # @return [Array<String>] All words in the cache.
    def refresh_cache
      if @cache
        words_array = @cache_store.retrieve_data
        words_array << generate_word while words_array.length < @cache_size
        @cache_store.store_data words_array
        words_array
      else
        []
      end
    end

    # Generate a new word, or return one from the cache if available.
    # @return [String] The word.
    def word
      if @cache
        load_word_from_cache
      else
        generate_word
      end
    end

    private

    def initialize_cache(opts)
      @cache = opts.fetch :cache, true
      @cache_file = opts.fetch :cache_file,
                               "tmp/markov_words_#{@gram_size}.cache"
      @cache_size = opts.fetch :cache_size, 70
      @cache_store = FileStore.new(file_path: @cache_file)
    end

    def initialize_data(opts)
      @corpus_file = opts.fetch :corpus_file,
                                '/usr/share/dict/words'
      @data_file = opts.fetch :data_file,
                              "tmp/markov_words_#{@gram_size}.data"
      @data_store = FileStore.new(file_path: @data_file)
    end

    def contains_vowel?(ary)
      if ary.length < 2
        true
      else
        ary.take(2).join.match(/[aeiou]/)
      end
    end

    # Generates an English (by default) -sounding word.
    def generate_word
      set_grams if @grams.nil?
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

        gram = pick_random_char(@grams[key])
        gram_array << gram
      end
      gram_array
    end

    # Set initial array of chars, which is taken from the @grams key list.
    # must contain a vowel in the first 2 chars (unless @gram_size == 1 in
    # which case any letter).
    def generate_initial_gram_array
      initial_gram_array = []

      all_grams_array = @grams.to_a
      gram_min_length = @gram_size < @min_length ? @gram_size : @min_length
      until initial_gram_array.length >= gram_min_length &&
            contains_vowel?(initial_gram_array)
        initial_gram_array = all_grams_array.sample[0].chars
      end
      initial_gram_array
    end

    # The word must be a random length, between @min and @max
    def generate_word_length
      word_length = 0
      until word_length >= @min_length
        word_length = SecureRandom.rand(@max_length)
      end
      word_length
    end

    def load_word_from_cache
      words_array = @cache_store.retrieve_data
      if words_array.nil? || words_array.empty?
        words_array = Array.new(@cache_size) { generate_word }
      end

      word = words_array.pop
      cache_store.store_data words_array

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

    def line_ending?(word)
      /[\r\n]/.match? word
    end

    def set_grams
      grams = @data_store.retrieve_data ||
              markov_corpus(@corpus_file, @gram_size)
      @data_store.store_data grams unless grams == @grams
      @grams = grams
    end
  end
end
