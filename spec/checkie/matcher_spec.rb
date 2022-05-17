require "spec_helper"

describe Checkie::Matcher do

  before do
    stub_pr
  end

  let(:instance) { Checkie::Parser.instance }
    
  before { instance.reinitialize }
  after { instance.reinitialize }

  let(:pr) { Checkie::Fetcher.new("https://api.github.com/repos/Alignable/AlignableWeb/pulls/2160").fetch_files }

  let(:matcher) { Checkie::Matcher.new(pr) }

  describe "#match" do
    it "returns nothing without any rules" do
      expect(matcher.match).to eq({})
    end

    it "returns matching rules if some are added" do

      instance.add_file_rule(:delete_concern, "You removed a concern")
      instance.add_matching_file("app/controllers/**") do |changes,files|
        files.removed do
          check(:delete_concern)
        end
      end

      expect(matcher.match).to eq({"delete_concern"=>[["app/controllers/concerns/onboarding_tracking_support.rb", {:url=>"https://github.com/Alignable/AlignableWeb/blob/895953eba6a2356ad96836b5988c85eb49defb35/app/controllers/concerns/onboarding_tracking_support.rb"} ]] })

    end
  end

end
