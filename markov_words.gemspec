
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'markov_words/version'

Gem::Specification.new do |spec|
  spec.name = 'markov_words'
  spec.version = MarkovWords::VERSION
  spec.authors = ['Donald Merand']
  spec.email = ['dmerand@explo.org']

  spec.summary = %{Generate words (not sentences) using Markov-chain techniques.}
  spec.description = %{It's often nice to have random English-sounding words, eg. for password generators. This library uses Markov-chain techniques on words, as opposed to many others which focus on sentences.}
  spec.homepage = 'https://github.com/exploration/markov_words'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split('\x0').reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'pry', '~> 0.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'yard', '~> 0.6'
end
