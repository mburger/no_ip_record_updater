# -*- encoding: utf-8 -*-
require File.expand_path('../lib/no_ip_record_updater/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Markus Burger"]
  gem.email         = ["markus.burger@uni-ak.ac.at"]
  gem.summary       = %q{A simple App to to check your WAN IP and update your no-ip.org Record}
  gem.description   = %q{}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "no_ip_record_updater"
  gem.require_paths = ["lib"]
  gem.version       = NoIpRecordUpdater::VERSION
  gem.extra_rdoc_files = ["LICENSE", "README.md"]
end
