# frozen-string-literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'markov_words/version'

Gem::Specification.new do |spec|
  spec.name = 'markov_words'
  spec.version = MarkovWords::VERSION
  spec.authors = ['Donald Merand']
  spec.email = ['donald@merand.org']

  spec.summary = <<~SUMMARY
    Generate words (not sentences) using Markov-chain techniques.}
  SUMMARY
  spec.description = <<~DESCRIPTION
    It's often nice to have random English-sounding words, eg. for password
    generators. This library uses Markov-chain techniques on words, as opposed
    to many others which focus on sentences.
  DESCRIPTION
  spec.homepage = 'https://github.com/dmerand/markov_words'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.1.4'
  spec.add_development_dependency 'minitest', '~> 5.15'
  spec.add_development_dependency 'pry', '~> 0.14.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'yard', '~> 0.9.12'

  spec.add_runtime_dependency 'sqlite3', '~> 1.3'

  spec.required_ruby_version = '~> 2.3'
end
