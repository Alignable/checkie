class Checkie::Runner
  # Action is the pull request action type
  def run(url, action)
    fetcher = Checkie::Fetcher.new(url)
    poster = Checkie::Poster.new(fetcher.details, dry_run: false)

    if action == "opened"
      poster.post_pr_rules_comment!(Checkie::Parser.instance.pr_rules)
    elsif action == "synchronize"
      data = fetcher.fetch_files

      matcher = Checkie::Matcher.new(data)
      rules = matcher.match

      poster.post_annotations!(rules)
    end
  end
end
