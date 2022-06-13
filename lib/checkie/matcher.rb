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

        if File.fnmatch(match_details[:pattern],filename)
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
