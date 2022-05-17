require "spec_helper"


describe Checkie::ChangeMatchSet do

  before do
    stub_pr
  end

  let(:pr) { Checkie::Fetcher.new("https://api.github.com/repos/Alignable/checkie/pulls/1").fetch_files }

  let(:matcher) { Checkie::Matcher.new(pr) }

  let(:match_set) { Checkie::ChangeMatchSet.new(matcher) } 

  describe "#add_patch" do
    it "adds the patch and includes line numbers" do
      
      file = pr[0]

      match_set.add_patch(file[:filename],file[:patch], url: file[:blob_url]) 

      expect(match_set.hunks[:added].length).to eq 45
      expect(match_set.hunks[:touched].length).to eq 45
      expect(match_set.hunks[:removed].length).to eq 0

      hunk = match_set.hunks[:added][0]
      expect(hunk[0]).to eq "# Setup\n"
      expect(hunk[1][:line].number).to eq 1
    end

  end

end

