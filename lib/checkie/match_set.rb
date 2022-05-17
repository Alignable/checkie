
class Checkie::MatchSet

  attr_reader :hunks, :matcher

  def initialize(matcher)
    @matcher = matcher
    @pr = matcher.pr
    @hunks = {
      added: [],
      removed: [],
      touched: [],
      renamed: []
    }
  end

  def present?
    @hunks[:touched].length > 0
  end

  def add_hunk(change_type,hunk, metadata={})
    @hunks[change_type.to_sym] << [ hunk, metadata ] if change_type.to_sym.in? [:added, :removed, :renamed]
    @hunks[:touched] << [ hunk, metadata ]
  end

  def match_hunk(hunk_type,pattern=nil,&block)
    pattern = /#{Regexp.escape(pattern)}/ if pattern.is_a?(String)
    matching = @hunks[hunk_type].select do |hunk|
      !pattern || pattern =~ hunk[0]
    end

    match_helper(matching,&block)
  end

  def match_helper(matching, &block)
    if block_given? && matching.length > 0
      result_set = Checkie::ResultSet.new(self, matching)

      result_set.run(&block)
    end
    matching
  end


  def added(pattern=nil, &block)
    match_hunk(:added, pattern, &block)
  end

  def removed(pattern=nil, &block)
    match_hunk(:removed, pattern, &block)
  end

  def touched(pattern=nil,&block)
    match_hunk(:touched, pattern, &block)
  end

end
