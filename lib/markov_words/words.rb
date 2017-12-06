module MarkovWords
  # This class takes care of word generation, caching, and data storage.
  class Words
    # Perform caching? Defaults to true.
    attr :cache
    # File location where you want to store the cache
    attr :cache_file
    # How many words you want to store in the cache?
    attr :cache_size
    # Your dictionary of words. Defaults to /usr/share/dict/words.
    attr :corpus_file
    # Where should your database be stored on disk?
    attr :data_file
    # The database of "grams" (word/count combinations), stored on the disk and
    # loaded into this variable in memory when generating words.
    attr :grams
    # Number of n-grams to compute for your database. Defaults to 2
    attr :gram_size
    # Max generated word length. Defaults to 16
    attr :max_length
    # Minimum generated word length. Defaults to 3. NOTE: If your corpus size
    # is very small (<1000 words or so), it's hard to guarantee a min_length
    # because so many n-grams will have no association, which terminates word
    # generation.
    attr :min_length

    # Create a new "Words" object
    # @param opts [Hash] options sent to the object. Any of the object
    #   attributes (eg `:cache_file` or `:gram_size`) are valid parameters to
    #   add to the `opts` hash.
    # @return [Words] A `MarkovWords::Words` object.
    def initialize(opts = {})
      @gram_size = opts.fetch :gram_size, 2
      @max_length = opts.fetch :max_length, 16
      @min_length = opts.fetch :min_length, 3

      @cache = opts.fetch :cache, true
      @cache_file = opts.fetch :cache_file,
        "tmp/markov_words_#{@gram_size}.cache"
      @cache_size = opts.fetch :cache_size, 70
      @corpus_file = opts.fetch :corpus_file,
        '/usr/share/dict/words'
      @data_file = opts.fetch :data_file,
        "tmp/markov_words_#{@gram_size}.data"
      @grams = nil
    end

    # "Top off" the cache of stored words, and ensure that it's at
    # `@cache_size`. If `@cache` is set to `false`, returns an empty array.
    # @return [Array<String>] All words in the cache.
    def refresh_cache
      if @cache
        words_array = load_from_file(@cache_file) || []
      
        while words_array.length < @cache_size
          words_array << generate_word
        end

        save_to_file(@cache_file, words_array)
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

    def contains_vowel?(ary)
      if ary.length < 2
        true
      else
        ary.take(2).join.match(/[aeiou]/)
      end
    end

    # Generates an English (by default)- sounding word.
    def generate_word
      set_grams if @grams.nil?

      gram = ''
      gram_array = []

      # The word must be a random length, between @min and @max
      desired_length = 0
      until desired_length >= @min_length
        desired_length = SecureRandom.rand(@max_length)
      end

      # Set initial array of chars, which is taken from the @grams key list. must
      # contain a vowel in the first 2 chars (unless @gram_size == 1 in which
      # case any letter).
      all_grams_array = @grams.to_a
      gram_min_length = @gram_size < @min_length ? @gram_size : @min_length
      until gram_array.length >= gram_min_length && contains_vowel?(gram_array)
        gram_array = all_grams_array.sample[0].chars
      end

      until gram_array.join.length == desired_length || gram.nil?
        # grab last @gram_size (or possibly fewer if the array is too small)
        # elements from the current gram_array, to use as the next key.
        gal = gram_array.length
        current_gram_size = gal >= @gram_size ? @gram_size : gal
        key = gram_array[-current_gram_size..-1].join

        gram = pick_random_char(@grams[key])
        gram_array << gram
      end

      gram_array.join
    end

    def generate_words_array
      @cache_size.times.map { generate_word }
    end

    def load_from_file(file)
      result = nil
      if File.exist?(file)
        File.open(file, 'r') {|f| result = Marshal.load(f)}
      end
      result
    end

    def load_word_from_cache
      words_array = load_from_file(@cache_file)
      if words_array.nil? || words_array.empty?
        words_array = generate_words_array 
      end

      word = words_array.pop
      save_to_file(@cache_file, words_array)

      word
    end

    # Generate a MarkovWords corpus from a datafile, with a given size of n-gram.
    # Returns a hash of "grams", which are a map of a letter to the frequency of
    # the letters that follow it, eg: {"c" => {"a" => 1, "b" => 2}}
    def markov_corpus(file, gram_size)
      grams = {}

      # Corpus contains a list of words, separated by newlines
      File.foreach(file) do |word|
        word = word.downcase.gsub(/-/, '')
        gram_size.downto(1) do |current_size|
          word.chars.each_cons(current_size + 1) do |gram|
            first = gram[0..current_size - 1].join
            second = gram[current_size]

            unless first.empty? || second.empty? || is_line_ending?(second)
              update_count(grams, first, second)
            end
          end
        end 
      end 

      grams
    end

    # Given a hash in the format: {"c" => {"a" => 1, "b" => 2}}, grab a random
    # element from the values hash, accurate to the distribution of counts.
    # In the example hash above, "a" would have a 33% chance of being chosen,
    # while "b" would have a 66% chance (1/2 ratio).
    def pick_random_char(counts_hash = {})
      if counts_hash.nil?
        return nil
      else
        total = counts_hash.values.sum
        pick_num = SecureRandom.rand(total)
        counter = 0
        counts_hash.each do |char, count|
          counter += count
          return char if counter >= pick_num 
        end
      end
    end

    def is_line_ending?(word)
      word.include?("\n")
    end

    # Marshal a Ruby object to file storage
    def save_to_file(file, data)
      File.open(file, 'wb') {|f| Marshal.dump(data, f)}
    end

    def set_grams
      if File.exist? @data_file
        @grams = load_from_file(@data_file)
      else
        @grams = markov_corpus(@corpus_file, @gram_size)
        save_to_file(@data_file, @grams)
      end
    end

    # Given a @grams entry, update the count of "second" in "first"
    #
    # Example:
    #     update_count({"a" => {"b" => 1}}, "a", "b")
    #     => {"a" => {"b" => 2}}
    def update_count(grams, first, second)
      grams[first] = {} if grams[first].nil?
      if grams[first][second].nil?
        grams[first][second] = 1
      else
        grams[first][second] += 1
      end
    end

  end
end
