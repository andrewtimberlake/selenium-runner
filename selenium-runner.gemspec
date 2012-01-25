Gem::Specification.new do |s|
  s.name             = "selenium-runner"
  s.version          = '0.0.2'
  s.authors          = ["Andrew Timberlake"]
  s.email            = "andrew@andrewtimberlake.com"
  s.description      = "A Parallel RSpec runner for running selenium specs in parallel"
  s.summary          = "selenium-runner"
  s.extra_rdoc_files = ["LICENSE"]
  s.files            = `git ls-files -- lib/*`.split(/\n/) + ["LICENSE"]
  s.executables      = `git ls-files -- bin/*`.split(/\n/).map{ |f| File.basename(f) }
  s.rdoc_options     = ["--charset=UTF-8"]
  s.require_path     = "lib"

  s.add_runtime_dependency "rspec", ">= 2.8.0"
  s.add_runtime_dependency "selenium-webdriver"
end
