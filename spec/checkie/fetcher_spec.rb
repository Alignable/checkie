require "spec_helper"


describe Checkie::Fetcher do
  before do
    ENV['GITHUB_TOKEN'] = "yo"
  end

  describe "#fetch_files" do
    it "grabs and returns the details of a PR" do
      stub_pr
      files = Checkie::Fetcher.new("https://api.github.com/repos/Alignable/AlignableWeb/pulls/2160").fetch_files
      expect(files.length).to eq 30
      expect(files.first[:filename]).to eq  "app/controllers/biz/email_oauth_controller.rb"
    end
  end
end
