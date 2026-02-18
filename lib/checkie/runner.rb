require "open3"
require "anthropic"
class Checkie::Runner
  # Action is the pull request action type
  def run(url, action)
    fetcher = Checkie::Fetcher.new(url)
    poster = Checkie::Poster.new(fetcher.details, dry_run: false)

    if action == "synchronize" || action == "opened"
      data = fetcher.fetch_files

      matcher = Checkie::Matcher.new(data)
      rules = matcher.match_ai
      ai_rules = call_claude(rules[:exploration]) + call_claude_api(rules[:standard])
      reg_rules = matcher.match
      poster.post_ai_annotations!(ai_rules)
      poster.post_annotations!(reg_rules)
    end
  end

  def call_claude(rule_mapping)
    # assumes that non-exploratory rules have been filtered out
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

  def call_claude_api(rule_mapping)
    # Assumes that exploratory rules have been filtered out
    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])

    rule_mapping.map do |mapping|
      # mapping == [rule strings joined by \n, arr of patch diffs]
      prompt = create_prompt(mapping[0], mapping[1])

      begin
        response = client.messages.create(
          model: "claude-haiku-4-5-20251001",
          max_tokens: 4096,
          messages: [
            {
              role: "user",
              content: prompt
            }
          ],
          tools: [
            {
              name: "report_violations",
              description: "Report code style violations found in the PR diff",
              input_schema: structured_schema
            }
          ],
          tool_choice: {
            type: "tool",
            name: "report_violations"
          }
        )

        # Extract the tool use result
        tool_use = response.content&.find { |block| block.type == :tool_use }
        if tool_use && tool_use.input
          tool_use.input
        else
          puts "No tool use found in response"
          { "violations" => [] }
        end
      rescue => e
        puts "Error calling Claude API: #{e.message}"
        { "violations" => [] }
      end
    end
  end

  def structured_schema
    {
      type: "object",
      properties: {
        violations: {
          type: "array",
          items: {
            type: "object",
            properties: {
              file: { type: "string", description: "Path to the file" },
              rule: { type: "string", description: "Name of the rule violated" },
              line_number: { type: "integer", description: "Line number in the diff (must be a + or - line)" },
              issue: { type: "string", description: "Description of what's wrong" },
              suggestion: { type: "string", description: "How to fix the issue" }
            },
            required: ["file", "rule", "line_number", "issue", "suggestion"]
          }
        }
      },
      required: ["violations"]
    }
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
    One block / line of code may violate multiple rules. Include any and all violations.

    Instructions:
    1. For each changed file, check if modified lines ONLY WITHIN THE DIFF violate any rules. 
      1.1 DO NOT make your own assumptions about how to interpret the rules
      1.2 DO NOT make up your own rules, such as grammar violations
      1.3 DO NOT RESPOND WITH VIOLATIONS ON UNCHANGED CODE
    2. You may read all related files for context

    Ensure all parts of your response are succinct and to the point. DO NOT ramble.
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
