# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_record_data_loader/version"

Gem::Specification.new do |spec|
  spec.name          = "active_record_data_loader"
  spec.version       = DataLoader::VERSION
  spec.authors       = ["Alejandro Beiderman"]
  spec.email         = ["abeiderman@gmail.com"]

  spec.summary       = "A utility to bulk load test data for performance testing."
  spec.description   = "A utility to bulk load test data for performance testing."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 4.0"
  spec.add_dependency "faker", ">= 1.9"

  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "bundler", ">= 1.16"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-collection_matchers"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "sqlite3"
end
