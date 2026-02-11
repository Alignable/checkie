require "singleton" 
class Checkie::Parser
  include Singleton

  attr_reader :matches, :rules, :matches_ai, :rules_ai

  def initialize
    reinitialize
  end

  def reinitialize
    @rules = {}
    @rules_ai = {}
    @matches = []
    @matches_ai = []
  end

  def add_matching_file(glob_pattern, matching_proc=nil, **opts, &block)
    matching_proc ||= block
    obj = { pattern: glob_pattern, 
            matching_proc: matching_proc 
          }
    if opts[:ai]
      obj[:rules] = opts[:rules].map do |r|
        @rules_ai[r.to_s]
      end
      if opts[:exclude]
         obj[:exclude] = opts[:exclude]
      end
      @matches_ai << obj
    else
      @matches << obj
    end
  end

  def add_file_rule(name, description, exploration=false, references: [], ai: false)
    raise "Duplicate rule #{name}" if @rules_ai[name.to_s].present? || @rules_ai[name.to_s].present?
    if ai
      @rules_ai[name.to_s] = {
        name: name.to_s,
        description: description,
        exploration: exploration
      }
    else
      @rules[name.to_s] = {
                  name: name.to_s,
                  description: description,
                  references: references
                }
    end
  end

end
