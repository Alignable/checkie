Gem::Specification.new do |s|
  s.name = %q{checkie}
  s.version = "0.0.3"
  s.authors = %q{Alignable}
  s.date = %q{2026-02-04}
  s.summary = %q{Hi, It's Checkie! Looks like you're trying to write some code}
  s.files = [
    "lib/checkie.rb"
  ]
  s.require_paths = ["lib"]
  s.license       = 'MIT'

  s.add_runtime_dependency 'dotenv'
  s.add_runtime_dependency "octokit"
  s.add_runtime_dependency "git_diff_parser"
  s.add_runtime_dependency "activesupport"

  # to write specs for rules.rb
  s.add_runtime_dependency "rspec"
  s.add_runtime_dependency "webmock"
end
