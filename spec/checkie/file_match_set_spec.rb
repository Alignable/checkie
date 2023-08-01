require "spec_helper"


describe Checkie::FileMatchSet do

  before do
    stub_pr
  end

  let(:pr) { Checkie::Fetcher.new("https://api.github.com/repos/Alignable/checkie/pulls/1").fetch_files }

  let(:matcher) { Checkie::Matcher.new(pr) }

  let(:all_match_set) { Checkie::FileMatchSet.new(matcher) }
  let(:match_set) { Checkie::FileMatchSet.new(matcher, all_files: all_match_set) } 

  describe "#add_hunk" do
    it "adds added hunks" do
      match_set.add_hunk("added", "app/something/something.rb")

      expect(match_set.hunks[:added].length).to eq 1
      expect(match_set.hunks[:touched].length).to eq 1
      expect(match_set.hunks[:removed].length).to eq 0
      expect(match_set.hunks[:renamed].length).to eq 0
    end

    it "adds removed hunks" do
      match_set.add_hunk("removed", "app/something/something.rb")

      expect(match_set.hunks[:added].length).to eq 0
      expect(match_set.hunks[:touched].length).to eq 1
      expect(match_set.hunks[:removed].length).to eq 1
      expect(match_set.hunks[:renamed].length).to eq 0
    end

    it "adds renamed hunks" do
      match_set.add_hunk("renamed", "app/something/something.rb")

      expect(match_set.hunks[:added].length).to eq 0
      expect(match_set.hunks[:touched].length).to eq 1
      expect(match_set.hunks[:removed].length).to eq 0
      expect(match_set.hunks[:renamed].length).to eq 1
    end
  end

  describe "#match_hunk" do
    it "returns false if there are no matching hunks" do
      expect(match_set.match_hunk(:added)).to eq []
    end

    it "returns all matching if no pattern is provided" do
      match_set.add_hunk("added", "app/something/something.rb")
      expect(match_set.match_hunk(:added)).to eq [["app/something/something.rb",{}]]
    end

    it "returns patterns that match a string if a pattern is provided" do
      match_set.add_hunk("added", "app/models/something.rb")
      match_set.add_hunk("added", "app/something/something.rb")
      expect(match_set.match_hunk(:added,"models")).to eq [["app/models/something.rb",{}]]
    end

    it "returns patterns that match a regexp if a pattern is provided" do
      match_set.add_hunk("added", "app/models/something.rb")
      match_set.add_hunk("added", "app/something/something.rb")
      match_set.add_hunk("added", "app/models/something.ex")
      expect(match_set.match_hunk(:added,/rb$/)).to eq [["app/models/something.rb", {}], ["app/something/something.rb", {}]]
    end

    it "calls a block if one is given" do
      match_set.add_hunk("added", "app/models/something.rb")

      block_called = 0
      match_set.match_hunk(:added,"models") do
        block_called += 1
      end

      expect(block_called).to eq 1
    end

    it "does an instance eval on the result set" do
      match_set.add_hunk("added", "app/models/something.rb")
      match_set.add_hunk("added", "app/something/something.rb")
      match_set.add_hunk("added", "app/models/something.ex")
      len = 0
      match_set.match_hunk(:added) do
        len = length
      end

      expect(len).to eq 3
    end

    it "allows entering checks into the matcher" do
      match_set.add_hunk("added", "app/models/something.rb")
      match_set.add_hunk("added", "app/something/something.rb")
      match_set.add_hunk("added", "app/models/something.ex")
      len = 0
      match_set.match_hunk(:added) do
        check(:somethinger)
      end

      expect(matcher.rules.length).to eq 1
      expect(matcher.rules["somethinger"].length).to eq 3
    end
  end

  describe "#added" do
    it "only matches added hunks" do
      match_set.add_hunk("added", "app/models/something.rb")
      match_set.add_hunk("renamed", "app/views/something.html")
      match_set.add_hunk("removed", "app/something/something.rb")
      match_set.add_hunk("removed", "app/models/something.ex")
      expect(match_set.added.length).to eq 1
    end
  end

  describe "#added_lines" do
    it "only matches files that added at least those lines" do
      match_set.add_hunk("added", "app/models/something.rb", additions: 10)
      match_set.add_hunk("added", "app/models/something.rb", additions: 5)
      match_set.add_hunk("modified", "app/models/something.ex", additions: 10)
      expect(match_set.added_lines(8).length).to eq 2
    end
  end

  describe "#removed" do
    it "only matches removed hunks" do
      match_set.add_hunk("added", "app/models/something.rb")
      match_set.add_hunk("renamed", "app/views/something.html")
      match_set.add_hunk("removed", "app/something/something.rb")
      match_set.add_hunk("removed", "app/models/something.ex")
      expect(match_set.removed.length).to eq 2
    end
  end

  describe "#touched" do
    it "matches all hunks" do
      match_set.add_hunk("added", "app/models/something.rb")
      match_set.add_hunk("renamed", "app/views/something.html")
      match_set.add_hunk("removed", "app/something/something.rb")
      match_set.add_hunk("changed", "app/models/something.ex")
      expect(match_set.touched.length).to eq 4
    end
  end

  describe "removed" do
    it "only matches renamed hunks" do
      match_set.add_hunk("added", "app/models/something.rb")
      match_set.add_hunk("renamed", "app/something/something.rb")
      match_set.add_hunk("removed", "app/models/something.ex")
      expect(match_set.renamed.length).to eq 1
    end
  end

  describe "#without" do
    it "returns hunks without matching specs" do
      match_set.add_hunk("added", "app/models/something.rb")
      expect(match_set.without(:spec).length).to eq 1
    end

    it "doesn't return hunks if they have matching files" do
      all_match_set.add_hunk("added","spec/models/something_spec.rb")
      match_set.add_hunk("added", "app/models/something.rb")

      expect(match_set.without(:spec).length).to eq 0
    end

    context "with further nesting" do
      it "returns hunks without matching specs" do
        match_set.add_hunk("added", "rails/app/models/something.rb")
        expect(match_set.without('rails/spec', '_spec').length).to eq 1
      end

      it "doesn't return hunks if they have matching files" do
        all_match_set.add_hunk("added","rails/spec/models/something_spec.rb")
        match_set.add_hunk("added", "rails/app/models/something.rb")

        expect(match_set.without('rails/spec', '_spec').length).to eq 0
      end
    end
  end

end
