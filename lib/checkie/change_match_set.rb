require "git_diff_parser" 

class Checkie::ChangeMatchSet < Checkie::MatchSet

  def add_patch(filename,patch, metadata={})
    parsed = GitDiffParser::Patch.new(patch)

    parsed.changed_lines.each do |line|
      add_hunk(:added,line.content[1..-1], { filename: filename, line: line}.merge(metadata) )
    end

    parsed.removed_lines.each do |line|
      add_hunk(:removed,line.content[1..-1], { filename: filename, line: line }.merge(metadata))
    end
  end
end
