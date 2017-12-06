# MarkovWords

At [EXPLO](https://www.explo.org), we often have a need for specific vocabulary-generators. For example, we might want to make a [password generator](http://lab.explo.org/password), or a Harry Potter house-generator, or some such thing.

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

words = MarkovWords::Words.new
# returns a random word
puts words.word 
```

You might prefer using a number of n-grams (letter combinations being tracked) higher than the default number (which is 2). We've found that the higher you go, the more accurate words tend to sound, at the expense of having to generate a much larger database of n-gram => letter correspondences. In the case of the default `/usr/share/dict` file, `gram_size = 1` yields a roughly `3.2Kb` database size; `gram_size = 2` yields `3.2Kb`. Once you get up to `gram_size = 8`, you're into ~`30MB` territory, which slows things down a bit. 

To set gram_size:

```ruby
words = MarkovWords::words.new(gram_size: 8)
# Will take a while the first time, while the database is created.
puts words.word 
```

### Dictionary

By default, `MarkovWords` will use the system dictionary located (on Macs) in `/usr/share/dict/words`. You can change this setting:

```ruby
# eg to generate random proper names instead of English-sounding words.
words = MarkovWords::Words.new(corpus_file: '/usr/share/dict/propernames')
```

This is pretty great, because it means that if you have a dictionary to emulate, you can make words that sound like anything!

### Data Storage

`MarkovWords` stores its database of n-gram concurrences in `Marshal`'ed text files on disk and loads it into memory when necessary. You can control the location of the data file with:

```ruby
# eg to store the data in /tmp/markov.data
words = MarkovWords::Words.new(data_file: /tmp/markov.data)
```

### Caching

Because calculation can get slow, especially at high n-gram sizess, `MarkovWords` will cache 100 words into a `words_ngramsize.cache` file by default. If you want to control caching, you can adjust caching parameters eg:

```ruby
# For no caching whatsoever
words = MarkovWords::Words.new(cache: false)

# To change the number of pre-computed/stored words to 1000:
words = MarkovWords::Words.new(cache_size: 1000)

# To change the location of the cache file to /tmp/markov.cache:
words = MarkovWords::Words.new(cache_file: '/tmp/markov.cache')

# Of course, options can be combined:
words = MarkovWords::Words.new(
  cache_file: '/tmp/markov.cache',
  cache_size: 1000
)
```

Lastly, you can "top off" the cache to make sure it's full with:

```ruby
words = MarkovWords::Words.new
words.refresh_cache
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/markov_words. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MarkovWords project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/exploration/markov_words/blob/master/CODE_OF_CONDUCT.md).
