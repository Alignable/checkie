
class Checkie::ResultSet 

  def initialize(match_set, matching)
    @match_set = match_set
    @matching = matching
  end

  def length
    @matching.length
  end

  def check(rule_name)
    @match_set.matcher.check(rule_name,@matching)
  end

  def run(&block)
    instance_eval &block
  end
  
end
