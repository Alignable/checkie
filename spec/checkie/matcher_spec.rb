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

end
