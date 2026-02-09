class Checkie::Matcher

  attr_reader :pr, :rules

  def initialize(pr)
    @pr = pr
    @rules = {}
  end

  def parser
    @parser = Checkie::Parser.instance
  end

  def check(rule,references = nil )
    @rules[rule.to_s] ||= []
    @rules[rule.to_s] += references if references
  end

  def check_rule(rule)
    @rules[rule.to_s] ||= []
    rule
  end


  def match_ai
    ruleset_to_files = {}
    @pr.each do |file|
      rules = gather_rules_ai(file[:filename])
      next if rules.empty?
      changeset = {name: file[:filename], patch: file[:patch]}
      if ruleset_to_files.key?(rules)
        ruleset_to_files[rules].append(changeset)
      else
        ruleset_to_files[rules] = [changeset]
      end
    end
    ruleset_to_files.map do |k,v|
      [k.join("\n"), v]
    end
  end

  def gather_rules_ai(path)
    applicable = Set[]
    parser.matches_ai.each do |rule|
      if File.fnmatch(rule[:pattern], path, File::FNM_EXTGLOB)
        next if rule[:exclude] && File.fnmatch(rule[:exclude],path, File::Constants::FNM_EXTGLOB)
        # rule[:text] = parser.rules_ai[rule[]]
        rule[:rules].each do |r|
          applicable.add(r[:description])
        end
      end
    end
    return applicable
  end

  def match
    all_files = Checkie::FileMatchSet.new(self)

    @pr.each do |file|
      filename = file[:filename]
      all_files.add_hunk(file[:status], filename, 
                        url: file[:blob_url])
    end

    parser.matches.each do |match_details|
      files = Checkie::FileMatchSet.new(self, all_files: all_files)
      changes = Checkie::ChangeMatchSet.new(self)

      @pr.each do |file|
        filename = file[:filename]
        patch = file[:patch]

        if File.fnmatch(match_details[:pattern],filename,File::FNM_EXTGLOB)
          files.add_hunk(file[:status],filename, url: file[:blob_url], additions: file[:additions], deletions: file[:deletions])

          # need to break changes into added and removed
          changes.add_patch(filename,patch,  url: file[:blob_url])
        end
      end

      if files.present?
        instance_exec(changes,files,&match_details[:matching_proc])
      end
    end

    @rules
  end
end
