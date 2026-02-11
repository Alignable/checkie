require "open3"
class Checkie::Runner
  # Action is the pull request action type
  def run(url, action)
    fetcher = Checkie::Fetcher.new(url)
    poster = Checkie::Poster.new(fetcher.details, dry_run: false)

    if action == "synchronize" || action == "opened"
      data = fetcher.fetch_files

      matcher = Checkie::Matcher.new(data)
      rules = matcher.match_ai
      to_post = call_claude(rules)
      poster.post_ai_annotations!(to_post)
      # poster.post_annotations!(rules)
    end
  end

  def call_claude(rule_mapping)
    rule_mapping.map do |mapping|
      # mappping == [rule strings joined by \n, arr of patch diffs]
      prompt = create_prompt(mapping[0], mapping[1])

      repo_dir = File.expand_path("../../", Dir.pwd)
      res = Open3.capture3("claude", "--model", "haiku", "--dangerously-skip-permissions", "-p", prompt, chdir: repo_dir)
      puts res[0]
      prefix = res[0].index("```json")
      postfix = res[0].index("```", prefix + 7)
      unless prefix && postfix
        puts "Bad response from Claude!!", res[0]
        next
      end
      parsed = res[0][prefix+7...postfix]
      JSON.parse(parsed)
    end
  end

  def create_prompt(rules, diffs)
    formatted =  diffs.map do |d|
      <<-PATCH
        File: #{d[:name]}
        #{d[:patch]}
      PATCH
    end
    <<-PROMPT
    You are an AI code reviewer, going through PRs and identifying any changes that 
    don't follow the teams established best practices.

    Code style rules:
    #{rules}

    Git PR diff to evaluate:
    #{formatted}

    IMPORTANT: The diff above only shows files matching the rules being checked. Before flagging
    any missing files (like spec files), you MUST use the Read tool or Glob tool to verify the file
    does not exist in the repository. Do not assume a file is missing just because it's not in the
    diff above - it may have been added elsewhere in the PR.

    Instructions:
    1. For each changed file, check if modified lines violate any rules
      1.1 Do not make your own assumptions about how to interpret the rules
    2. line_number MUST be a line that appears in the diff (lines starting with + or -)
    3. If a rule violation exists but no lines in the diff can be commented on, skip that violation
    4. You may read all related files for context
    5. IF THERE ARE NO VIOLATIONS DO NOT RETURN ANYTHING.

    Return valid JSON only:
    {
      "violations": [
        {
          "file": "path/to/file.rb",
          "rule": "rule name",
          "line_number": 10,
          "issue": "what's wrong",
          "suggestion": "how to fix"
        }
      ]
    }

    Return empty violations array if no issues found: {"violations": []}
    PROMPT
  end
end
