require "spec_helper"


describe Checkie::Parser do
  let(:instance) { Checkie::Parser.instance }

  before { instance.reinitialize }
  after { instance.reinitialize }


  describe "add_file_rule" do
    it "adds a rule to the list of rules" do
      expect do
        instance.add_file_rule(:something, "Because")
      end.to change { instance.rules.length }.by(1)

      expect(instance.rules["something"]).to be_present
    end
  end

  describe "add_pr_rule" do
    it "adds a rule to the list of rules" do
      expect do
        instance.add_pr_rule(:something, "Because")
      end.to change { instance.pr_rules.length }.by(1)

      expect(instance.pr_rules).to eq [["something", "Because"]]
    end
  end

  describe "add_matching_file" do
    it "adds a matching rule" do
      expect do
        instance.add_matching_file("app/models/**", Proc.new { })
      end.to change { instance.matches.length }.by(1)
    end
  end
end
