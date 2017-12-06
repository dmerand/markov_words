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

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/markov_words. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MarkovWords project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/markov_words/blob/master/CODE_OF_CONDUCT.md).
