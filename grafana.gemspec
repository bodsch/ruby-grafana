# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grafana/version'

Gem::Specification.new do |spec|

  spec.name          = 'grafana'
  spec.version       = Grafana::VERSION
  spec.authors       = ['Bodo Schulz']
  spec.email         = ['bodo@boone-schulz.de']

  spec.summary       = %q{Grafana HTTP API Wrapper}
  spec.description   = %q{A simple wrapper for the Grafana HTTP API}
  spec.homepage      = 'http://github.com/bodsch/ruby-grafana'

  spec.files         = Dir[
    'README.md',
    'LICENSE',
    'lib/**/*',
    'doc/*',
    'examples/*.rb'
  ]

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

#  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
#  spec.bindir        = "exe"
#  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency('rest-client', '~> 2.0')
  spec.add_dependency('json', '~> 2.1')

  begin

    if( RUBY_VERSION >= '2.0' )
      spec.required_ruby_version = '~> 2.0'
    elsif( RUBY_VERSION <= '2.1' )
      spec.required_ruby_version = '~> 2.1'
    elsif( RUBY_VERSION <= '2.2' )
      spec.required_ruby_version = '~> 2.2'
    elsif( RUBY_VERSION <= '2.3' )
      spec.required_ruby_version = '~> 2.3'
    end

    if( RUBY_VERSION < '2.3' )
      spec.add_dependency('ruby_dig')
    end

#    if( RUBY_VERSION >= '2.3' )
#      spec.add_dependency('openssl', '~> 2.0')
#    end
  rescue => e
    warn "#{$0}: #{e}"
    exit!
  end

#  spec.add_development_dependency('bundler', '~> 1.12')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rake-notes')
  spec.add_development_dependency('rubocop')
  spec.add_development_dependency('rubocop-checkstyle_formatter')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rspec_junit_formatter')
  spec.add_development_dependency('rspec-nc', '~> 0')
  spec.add_development_dependency('guard', '~> 0')
  spec.add_development_dependency('guard-rspec', '~> 0')
  spec.add_development_dependency('pry', '~> 0')
  spec.add_development_dependency('pry-remote', '~> 0')
  spec.add_development_dependency('pry-nav', '~> 0')

end
