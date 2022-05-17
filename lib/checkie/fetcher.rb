require "octokit"

# Grabs the PR details from Github
class Checkie::Fetcher 

  attr_reader :details

  def initialize(url)
    @pr_url = url

    @pr_url.gsub!("https://github.com/","https://api.github.com/repos/")
    @pr_url.gsub!("/pull/","/pulls/")

    @details = client.get(@pr_url)
  end

  def fetch_files
    repo_id = @details[:base][:repo][:id]
    pr_number = @details[:number]

    client.pull_request_files(repo_id, pr_number)
  end

  def save
    pr = fetch_files
    file = File.join("./spec","fixtures", "#{@details[:number]}.json")
    FileUtils.mkpath("./spec/fixtures")
    File.open(file,"wt") do |fp|
      fp.write(pr.to_json)
    end
  end


  def client
    Octokit.auto_paginate = true
    @client ||= Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
  end
end
