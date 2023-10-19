# frozen_string_literal: true

require_relative "lib/rubrik/version"

Gem::Specification.new do |spec|
  spec.name = "rubrik"
  spec.version = Rubrik::VERSION
  spec.authors = ["Tomás Coêlho"]
  spec.email = ["tomascoelho6@gmail.com"]

  spec.summary = "Sign PDFs digitally in pure Ruby"
  spec.description = "Sign PDFs digitally in pure Ruby"
  spec.homepage = "https://github.com/tomascco/rubrik"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tomascco/rubrik"
  spec.metadata["changelog_uri"] = "https://github.com/tomascco/rubrik/releases"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.glob("lib/**/*.rb") + ["README.md", "LICENSE.txt"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  spec.add_runtime_dependency "pdf-reader", "~> 2.10"
  spec.add_runtime_dependency "sorbet-runtime", "~> 0.5"
  spec.add_runtime_dependency "openssl", ">= 2.2.1"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
