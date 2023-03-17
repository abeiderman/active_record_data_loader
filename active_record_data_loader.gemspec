# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_record_data_loader/version"

Gem::Specification.new do |spec|
  spec.name          = "active_record_data_loader"
  spec.version       = ActiveRecordDataLoader::VERSION
  spec.authors       = ["Alejandro Beiderman"]
  spec.email         = ["active_record_data_loader@ossprojects.dev"]

  spec.summary       = "A utility to bulk load test data for performance testing."
  spec.description   = "A utility to bulk load test data for performance testing."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["source_code_uri"] = "https://github.com/abeiderman/active_record_data_loader"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
          "public gem pushes."
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5.0"

  spec.add_dependency "activerecord", ">= 5.0"
end
