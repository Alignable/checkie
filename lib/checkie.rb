lib_path = File.expand_path('.',__dir__) + "/checkie"

require "dotenv/load"
require 'active_support/all'

require "#{lib_path}/version" 

require "#{lib_path}/fetcher"
require "#{lib_path}/parser"
require "#{lib_path}/result_set"
require "#{lib_path}/match_set"
require "#{lib_path}/file_match_set"
require "#{lib_path}/change_match_set"
require "#{lib_path}/matcher"
require "#{lib_path}/poster"
require "#{lib_path}/runner"

def matching(file_pattern, &block)
  Checkie::Parser.instance.add_matching_file(file_pattern,&block)
end

def matching_ai(file_pattern, rules:, exclude: nil, &block)
  Checkie::Parser.instance.add_matching_file(file_pattern, ai: true, rules: rules, exclude: exclude, &block)
end


def file_rule(name,description,references:[])
  Checkie::Parser.instance.add_file_rule(name, description, references: references)
end

def file_rule_ai(name, description, opts: {})
  Checkie::Parser.instance.add_file_rule(name, description, opts)
end

def run(url, action)
  Checkie::Runner.new.run(url, action)
end
