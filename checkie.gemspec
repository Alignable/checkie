Gem::Specification.new do |s|
  s.name = %q{checkie}
  s.version = "0.0.1"
  s.authors = %q{Alignable}
  s.date = %q{2018-05-23}
  s.summary = %q{Hi, It's Checkie! Looks like you're trying to write some code}
  s.files = [
    "lib/checkie.rb"
  ]
  s.require_paths = ["lib"]
  s.license       = 'MIT'

  s.add_runtime_dependency 'dotenv'
  s.add_runtime_dependency "octokit", "~>4.22.0"
  s.add_runtime_dependency "git_diff_parser"
  s.add_runtime_dependency "activesupport"

  # to write specs for rules.rb
  s.add_runtime_dependency "rspec"
  s.add_runtime_dependency "webmock"
end
