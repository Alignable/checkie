class Checkie::FileMatchSet  < Checkie::MatchSet

  def initialize(matcher, all_files: nil )
    @all_files = all_files
    super(matcher)
  end

  def without(prefix,postfix = nil, &block)
    prefix = prefix.to_s # :spec => "spec"
    postfix ||= "_" + prefix  # _spec "
    matching = @hunks[:touched].select do |hunk|
      # app/models/test.rb > [ app, models, test.rb ]
      split = hunk[0].split("/")

      # if it's a spec file, don't care
      if split[0] == prefix
        false
      else
        # test.rb => test_spec.rb
        split[-1] = postfix_filename(split[-1],postfix)

        # [ app, models, test_spec.rb ] => [ spec, models, test_spec.rb ].join("/")
        matching_file = ([ prefix ] + split[1..-1]).join("/")

        # spec/models/test_spec.rb exists?
        !@all_files.hunks[:touched].map { |h| h[0] }.include?(matching_file)
      end
    end

    match_helper(matching,&block)
  end

  def added_lines(lines, &block)
    matching = @hunks[:touched].select do |hunk|
      hunk[1][:additions] > lines
    end
    match_helper(matching,&block)
  end

  def postfix_filename(filename,postfix)
    ext = File.extname(filename)
    basename = File.basename(filename,ext)
    "#{basename}#{postfix}#{ext}"
  end

  def renamed(pattern=nil,&block)
    match_hunk(:renamed, pattern, &block)
  end

end
