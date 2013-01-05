# -*- encoding: utf-8 -*-
require File.expand_path('../lib/saikuro/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = [ %{Zev Blut}, %{Max Schubert} ]
  gem.email         = [ %{zb@ubit.com}, %{perldork@webwizarddesign.com} ]
  gem.description   = %{Saikuro is a Ruby cyclomatic complexity (code complexity) analyzer}
  gem.summary       = %{Saikuro is a Ruby cyclomatic complexity analyzer.  When given Ruby
  source code Saikuro will generate a report listing the cyclomatic
  complexity of each method found.  In addition, Saikuro counts the
  number of lines per method and can generate a listing of the number of
  tokens on each line of code.}
  gem.homepage      = %{https://github.com/perldork/saikuro (orig. http://saikuro.rubyforge.org/}

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = %{saikuro}
  gem.require_paths = ["lib"]
  gem.version       = Saikuro::VERSION
  gem.rubyforge_project = 'saikuro'
  gem.has_rdoc      = true
  gem.extra_rdoc_files = ["USAGE"]
end
