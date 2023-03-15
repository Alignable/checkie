require "octokit"

class Checkie::Poster

  LINE_WIDTH = 70
  GITHUB_ANNOTATION_BATCH = 50

  def initialize(details, dry_run: true)
    @details = details
    @dry_run = dry_run
  end

  # Post file rules as annotations
  def post_annotations!(rules)
    if rules.length > 0
      annotations = annotations(rules)

      if @dry_run
        puts(annotations)
      else
        repo_id = @details[:base][:repo][:id]
        sha = @details[:head][:sha]
        check_run_id = client.check_runs_for_ref(repo_id, sha, check_name: "checkie")&.check_runs&.first&.id
        raise "Could not find checkie run" unless check_run_id.present?
        
        annotations.each_slice(GITHUB_ANNOTATION_BATCH) do |a|
          client.update_check_run(@details[:base][:repo][:id], check_run_id, output: { annotations: a, title: "Checkie", summary: "#{annotations.length} annotations" })
        end
      end
    end
  end

  private

  def annotations(rules)
    arr = []

    parser = Checkie::Parser.instance

    rules.each do |key, occurrences|
      rule = parser.rules[key.to_s]

      description = rule[:description] || key.to_s

      # resolved << [ , occurrences, rule[:name] ]
      occurrences.each do |occurrence|
        line = occurrence[1][:line]&.number || 1
        arr << {
          path: occurrence[1][:filename] || occurrence[0],
          start_line: line,
          end_line: line,
          title: rule[:name],
          message: format_message(description),
          annotation_level: "warning",
        }
      end
    end
    arr
  end

  def client
    @client ||= Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
  end

  # Split string into multiple lines of less than LINE_WIDTH length, without cutting off words
  def format_message(str)
    words = str.split
    lines = []
    words.each do |w|
      if lines.last && lines[-1]&.length + w.length < LINE_WIDTH
        lines[-1] += " " + w
      else
        lines << w
      end
    end
    lines.join("\n")
  end
end


