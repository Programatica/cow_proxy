# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'cow_proxy/version'

Gem::Specification.new do |s|
  s.name = %q{cow_proxy}
  s.version = CowProxy::Version::STRING
  s.platform = Gem::Platform::RUBY
  s.email = %q{sergio@programatica.es}
  s.authors = ["Sergio Cambra"]
  s.homepage = %q{http://github.com/Programatica/cow_proxy}
  s.summary = %q{Copy-on-write proxy class, to use with frozen objects}
  s.description = %q{Make a COW proxy for a frozen object (or deep frozen), it will delegate every read method to proxied object, wrap value in COW proxy if frozen. Trying to modify object will result in data stored in proxy.}
  s.require_paths = ["lib"]
  s.files = `git ls-files -- app config lib`.split("\n") + %w[LICENSE README.md]
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.licenses = ["MIT"]

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = '>= 2.3.0'
end
