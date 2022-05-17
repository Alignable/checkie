require "singleton" 
class Checkie::Parser
  include Singleton

  attr_reader :matches, :rules, :pr_rules

  def initialize
    reinitialize
  end

  def reinitialize
    @rules = {}
    @pr_rules = []
    @matches = []
  end

  def add_matching_file(glob_pattern, matching_proc=nil, &block)
    matching_proc ||= block
    @matches << { pattern: glob_pattern, 
                  matching_proc: matching_proc 
                }
  end

  def add_file_rule(name, description, references: [])
    raise "Duplicate rule #{name}" if @rules[name.to_s].present?
    @rules[name.to_s] = {
                name: name.to_s,
                description: description,
                references: references
              }
  end

  def add_pr_rule(name, description)
    @pr_rules << [name.to_s, description]
  end

end
