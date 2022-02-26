# MarkovWords
[![Gem Version](https://badge.fury.io/rb/markov_words.svg)](https://badge.fury.io/rb/markov_words)

As it turns out, [Markov Chains](http://www.thagomizer.com/blog/2017/11/07/markov-models.html) are an excellent way to create specific vocabularies by "training" a model against a set of words to determine common combinations.

While there are [quite](https://github.com/dabrorius/markov-noodles) a [few](https://github.com/dabrorius/markov-noodles) [wonderful](https://github.com/imikimi/literate_randomizer) Ruby libraries that do this, they all focus either on _actual_ English words, or on creating random _sentences_ but not words. We created this library to do the same thing, but with words, hence the name `MarkovWords`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'markov_words'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install markov_words

## Usage

Basic usage is as follows:

```ruby
require 'markov_words'

generator = MarkovWords::Generator.new
# returns a random word
puts generator.word 
```

You might prefer using a number of n-grams (letter combinations being tracked) higher than the default number (which is 2). We've found that the higher you go, the more accurate words tend to sound, as the likelihood that you've started with a partial word the entire length of a word from your dictionary goes up. The increased "real-sounding-ness" comes at the expense of having to generate a much larger database of n-gram => letter correspondences, and accordingly slower access times. 

To set gram_size:

```ruby
generator = MarkovWords::Generator.new(gram_size: 7)
# Will take a while the first time, while the database is created.
puts generator.word 
```

### Dictionary

By default, `MarkovWords` will use the system dictionary located (on Macs) in `/usr/share/dict/words`. You can change this setting:

```ruby
# eg to generate random proper names instead of English-sounding words.
generator = MarkovWords::Generator.new(corpus_file: '/usr/share/dict/propernames')
```

This is pretty great, because it means that if you have a dictionary to emulate, you can make words that sound like anything!

### Data Storage

`MarkovWords` stores its database of n-gram concurrences on disk and loads it into memory when necessary. You can control the location of the data file with:

```ruby
# eg to store the data in /tmp/markov.data
generator = MarkovWords::Generator.new(data_file: /tmp/markov.data)
```

You can also clear out the contents of the data file (because `MarkovWords` will re-use it by default), by passing `flush_data: true`:

```ruby
# eg to store the data in /tmp/markov.data
generator = MarkovWords::Generator.new(data_file: /tmp/markov.data, flush_data: true)
```

### Custom Metadata

A `Generator` object gives you access to its `.data_store`, which is an instance of a `FileStore` object. This gives you the ability to store custom metadata into the same database that holds the n-gram information.

One example of how you might use this would be to cache words for later use (since initial word generation can be slow, even after the database has been generated the first time):

```ruby
generator = MarkovWords::Generator.new
my_cache = 100.times.map { generator.word }
generator.data_store.store_data :cache, my_cache

# then later, perhaps on another page load in a web server...
my_cache = generator.data_store.retrieve_data :cache
```

### Benchmarking

We've included a `bin/benchmark` script, which will measure initial load times, and then the time it takes to generate 100 words at various dictionary n-gram sizes.

Here is an example run:
```
bin/benchmark 1 6 '/usr/share/dict/words'
Minimum n-gram size set to 1
Maximum n-gram size set to 6
Corpus file set to /usr/share/dict/words

Test initial database creation time versus gram size? (y/n) y
------------------------------------------------------------
user     system      total        real
size: 1   4.080000   0.010000   4.090000 (  4.108898)
size: 2   8.320000   0.090000   8.410000 (  8.554122)
size: 3  12.710000   0.080000  12.790000 ( 12.869257)
size: 4  18.750000   0.160000  18.910000 ( 19.102232)
size: 5  25.440000   0.250000  25.690000 ( 25.953532)
size: 6  31.060000   0.340000  31.400000 ( 31.680680)
------------------------------------------------------------

Test existing database on disk, initial memory load? (y/n) y
------------------------------------------------------------
user     system      total        real
size: 1   0.000000   0.000000   0.000000 (  0.000587)
size: 2   0.000000   0.000000   0.000000 (  0.005109)
size: 3   0.080000   0.010000   0.090000 (  0.077303)
size: 4   0.330000   0.070000   0.400000 (  0.395079)
size: 5   1.030000   0.130000   1.160000 (  1.157014)
size: 6   2.920000   0.120000   3.040000 (  3.045219)
------------------------------------------------------------

Test word generation averages for 100 words per gram size? (y/n) y
------------------------------------------------------------
user     system      total        real
size: 1   0.010000   0.000000   0.010000 (  0.003971)
size: 2   0.010000   0.000000   0.010000 (  0.009460)
size: 3   0.120000   0.000000   0.120000 (  0.127297)
size: 4   0.350000   0.010000   0.360000 (  0.354564)
size: 5   2.250000   0.020000   2.270000 (  2.302405)
size: 6   4.000000   0.120000   4.120000 (  4.186757)
------------------------------------------------------------
```

## Change Log

- `2.0.0`
    - Breaking changes:
      - Removed all caching functions from `Generator`. They were cluttering up the code, without being a necessary function of a `Generator`.
      - Added an `attr_accessor` for `Generator.data_store`, so that users can implement custom metadata for `Generator` objects, and store it in the same `FileStore` object that holds the database.
- `1.0.0` introduced a couple of breaking changes:
    - `Words` class renamed to `Generator`.
    - `Generator`:
        - `cache: [boolean]` parameter was re-named to `perform_caching: [boolean]`.
        - Removed a lot of `attr_accessor` variables such as `data_store`, `min_length`, `max_length` etc., in favor of a leaner + cleaner API.
        - The cache file is no longer persisted to disk separately (because `FileStore` is using SQLite instead of direct-disk storage).
- `0.2.x` was all about Rubocop compliance, so it was a few method refactors but nothing major.
- `0.1.0` initial commit

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dmerand/markov_words. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MarkovWords project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/dmerand/markov_words/blob/master/CODE_OF_CONDUCT.md).
