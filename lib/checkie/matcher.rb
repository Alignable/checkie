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
    ruleset_to_files = {exploration: {}, standard: {}}
    @pr.each do |file|
      std_rules, exp_rules = gather_rules_ai(file[:filename])
      next if std_rules.empty? && exp_rules.empty?

      changeset = {name: file[:filename], patch: file[:patch]}
      unless exp_rules.empty?
        subset_key = :exploration
        ruleset_to_files[subset_key][exp_rules] ||= []
        ruleset_to_files[subset_key][exp_rules] << changeset
      end
      unless std_rules.empty?
        subset_key = :standard
        ruleset_to_files[subset_key][std_rules] ||= []
        ruleset_to_files[subset_key][std_rules] << changeset
      end
    end

    {
      exploration: ruleset_to_files[:exploration].map { |k, v| [k.join("\n"), v] },
      standard: ruleset_to_files[:standard].map { |k, v| [k.join("\n"), v] }
    }
  end

  def gather_rules_ai(path)
    applicable = Set[]
    exploration = Set[]
    parser.matches_ai.each do |rule|
      next unless File.fnmatch(rule[:pattern], path, File::FNM_EXTGLOB)
      next if rule[:exclude] && rule[:exclude].any? { |p| File.fnmatch(p, path, File::FNM_EXTGLOB) }

      rule[:rules].each do |r|
        if r[:exploration]
          exploration.add(r[:description])
        else
          applicable.add(r[:description])
        end
      end
    end
    [applicable, exploration]
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
