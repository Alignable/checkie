require "spec_helper"

describe Checkie::Matcher do

  before do
    stub_pr
  end

  let(:instance) { Checkie::Parser.instance }
    
  before { instance.reinitialize }
  after { instance.reinitialize }

  let(:pr) { Checkie::Fetcher.new("https://api.github.com/repos/Alignable/checkie/pulls/1").fetch_files }

  let(:matcher) { Checkie::Matcher.new(pr) }

  describe "#match" do
    it "returns nothing without any rules" do
      expect(matcher.match).to eq({})
    end

    it "returns matching rules if some are added" do

      instance.add_file_rule(:readme, "You edited readme")
      instance.add_matching_file("README*") do |changes,files|
        files.added do
          check(:readme)
        end
      end

      expect(matcher.match).to eq({"readme"=>[["README.md", {additions: 45, deletions: 0, :url=>"https://github.com/Alignable/checkie/blob/dd52731e1f894f53e5972e57255405961ca4ab38/README.md"}]] })

    end

    it 'supports extglob' do
      instance.add_matching_file("{README,abc}*") do |changes,files|
        files.added do
          check(:readme)
        end
      end
      expect(matcher.match).to eq({"readme"=>[["README.md", {additions: 45, deletions: 0, :url=>"https://github.com/Alignable/checkie/blob/dd52731e1f894f53e5972e57255405961ca4ab38/README.md"}]] })
    end
  end

  describe "#match_ai" do
    it "returns empty rulesets without any AI rules" do
      expect(matcher.match_ai).to eq({exploration: [], standard: []})
    end

    it "returns standard rules when AI rules are added" do
      instance.add_file_rule(:readme_check, "You edited readme", {ai: true})
      instance.add_matching_file("README*", ai: true, rules: [:readme_check])

      result = matcher.match_ai
      expect(result[:standard].length).to eq(1)
      expect(result[:standard][0][0]).to eq("You edited readme")
      expect(result[:standard][0][1].length).to eq(1)
      expect(result[:standard][0][1][0][:name]).to eq("README.md")
      expect(result[:exploration]).to eq([])
    end

    it "returns exploration rules when marked as exploration" do
      instance.add_file_rule(:readme_explore, "Consider readme impact", {ai: true, exploration: true})
      instance.add_matching_file("README*", ai: true, rules: [:readme_explore])

      result = matcher.match_ai
      expect(result[:exploration].length).to eq(1)
      expect(result[:exploration][0][0]).to eq("Consider readme impact")
      expect(result[:exploration][0][1].length).to eq(1)
      expect(result[:exploration][0][1][0][:name]).to eq("README.md")
      expect(result[:standard]).to eq([])
    end

    it "separates standard and exploration rules" do
      instance.add_file_rule(:readme_check, "You edited readme", {ai: true})
      instance.add_file_rule(:readme_explore, "Consider readme impact", {ai: true, exploration: true})
      instance.add_matching_file("README*", ai: true, rules: [:readme_check, :readme_explore])

      result = matcher.match_ai
      expect(result[:standard].length).to eq(1)
      expect(result[:exploration].length).to eq(1)
      expect(result[:standard][0][0]).to eq("You edited readme")
      expect(result[:exploration][0][0]).to eq("Consider readme impact")
    end

    it "supports exclude patterns" do
      instance.add_file_rule(:readme_check, "You edited readme", {ai: true})
      instance.add_matching_file("*", ai: true, rules: [:readme_check], exclude: "README*")

      result = matcher.match_ai
      expect(result[:standard]).to eq([])
      expect(result[:exploration]).to eq([])
    end

    it "supports array of exclude patterns" do
      instance.add_file_rule(:readme_check, "You edited readme", {ai: true})
      instance.add_matching_file("*", ai: true, rules: [:readme_check], exclude: ["README*", "LICENSE*"])

      result = matcher.match_ai
      expect(result[:standard]).to eq([])
      expect(result[:exploration]).to eq([])
    end
  end

  describe "#gather_rules_ai" do
    it "returns empty sets for non-matching paths" do
      instance.add_file_rule(:readme_check, "You edited readme", {ai: true})
      instance.add_matching_file("README*", ai: true, rules: [:readme_check])

      standard, exploration = matcher.gather_rules_ai("other_file.txt")
      expect(standard.to_a).to eq([])
      expect(exploration.to_a).to eq([])
    end

    it "returns standard rules for matching paths" do
      instance.add_file_rule(:readme_check, "You edited readme", {ai: true})
      instance.add_matching_file("README*", ai: true, rules: [:readme_check])

      standard, exploration = matcher.gather_rules_ai("README.md")
      expect(standard.to_a).to eq(["You edited readme"])
      expect(exploration.to_a).to eq([])
    end

    it "returns exploration rules for matching paths" do
      instance.add_file_rule(:readme_explore, "Consider readme impact", {ai: true, exploration: true})
      instance.add_matching_file("README*", ai: true, rules: [:readme_explore])

      standard, exploration = matcher.gather_rules_ai("README.md")
      expect(standard.to_a).to eq([])
      expect(exploration.to_a).to eq(["Consider readme impact"])
    end

    it "excludes paths matching exclude pattern" do
      instance.add_file_rule(:readme_check, "You edited readme", {ai: true})
      instance.add_matching_file("*", ai: true, rules: [:readme_check], exclude: ["README*"])

      standard, exploration = matcher.gather_rules_ai("README.md")
      expect(standard.to_a).to eq([])
      expect(exploration.to_a).to eq([])
    end

    it "excludes paths matching any pattern in exclude array" do
      instance.add_file_rule(:doc_check, "You edited documentation", {ai: true})
      instance.add_matching_file("*", ai: true, rules: [:doc_check], exclude: ["README*", "LICENSE*"])

      standard_readme, exploration_readme = matcher.gather_rules_ai("README.md")
      expect(standard_readme.to_a).to eq([])
      expect(exploration_readme.to_a).to eq([])

      standard_license, exploration_license = matcher.gather_rules_ai("LICENSE.txt")
      expect(standard_license.to_a).to eq([])
      expect(exploration_license.to_a).to eq([])

      standard_other, exploration_other = matcher.gather_rules_ai("other_file.rb")
      expect(standard_other.to_a).to eq(["You edited documentation"])
      expect(exploration_other.to_a).to eq([])
    end
  end

end
