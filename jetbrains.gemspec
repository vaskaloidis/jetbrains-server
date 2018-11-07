
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jetbrains/version"

Gem::Specification.new do |spec|
  spec.name          = "jetbrains"
  spec.version       = Jetbrains::VERSION
  spec.authors       = ["cyclops13"]
  spec.email         = ["cyclops@gmail.com"]

  spec.summary       = "ide server"
  spec.description   = "IDE Server"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
    spec.add_dependency 'sinatra'
  spec.add_dependency 'openssl'
  spec.add_dependency 'trollop'
  spec.add_dependency 'logger'
  spec.add_dependency 'colorize'
  spec.add_dependency 'ngrok-tunnel'
end
