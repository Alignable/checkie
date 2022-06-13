# Checkie

Hi, It's Checkie! Looks like you are trying to write some rules?

## Adding Rules

So, let's say you wrote a PR and I missed something I should have caught (Sorry). Here's the steps to add a new rule in:

0. Download checkie and do a `bundle install`
1. [Create a personal access token on GitHub](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) and add it to a .env file:
    GITHUB_TOKEN: THE_TOKEN_GOES_HERE
     
2. Load checkie from the console, fetch the PR and save it to spec/fixtures:
   
   ```
   $ bundle exec irb
   2.4.2 :001 > require "./rules"
   2.4.2 :001 > Checkie::Fetcher.new("https://github.com/Alignable/checkie/pull/2214").save
   ```

   (This will create a file called `spec/fixtures/2214.json`) 
   Also find a PR that doesn't match either already in the spec/fixtures directory or
   download another one.

3. Add a test to `spec/rules_spec.rb` like:

   ```
   describe ":my_new_rule" do
     it "matches my new rule if it ..." do
      expect(pr(2214)).to match_rule(:my_new_rule)
     end

     it "doesn't match my new rule if ..." do
      expect(pr(OTHER_PR_NUMBER)).to_not match_rule(:my_new_rule)
     end
   end
   ```

4. Run the test and make sure it fails: `bundle exec rspec spec/rules_spec.rb:LINE_NUMBER`

5. Add your rule into `rules.rb`, run the spec and make sure it passes and submit a PR.

## Rules DSL

Checkie works by checking PRs for different matching [file globs](https://ruby-doc.org/core-2.5.1/Dir.html#method-c-glob) and then adding check's in based on whether files or lines of code have been added, removed or touched. 

You define rules with a symbol ahead of time and then can add that rule in multiple matching blocks. Here's a simple example:

```
# Define a rule
file_rule :query_preloads,
  "Looks like you're querying an ActiveRecord model, did you check the console for speed and N+1's?"

# Determine the files we want to look for this rule in
matching("app/models/**.rb") do |changes, files| 

  # changes is a match set that contains all lines of the PR app/models/**.rb
  # files is a match set that contains all files of the PR in app/models/**.rb

  # changes and files all support added, removed and touched matchers
  # each of those matches can take no parameters (were there any?) or
  # a string or regexp to match.

  # if there are any added lines that contain the string ".where(" execute the block
  changes.added(".where(") do
    # add a check 
    check(:query_preloads)
  end

  # if you removed any files that have angle in the filename, execute the block
  files.removed(/angle/) do
    ...
  end

  # if you added any files 
  files.added do
    ...
  end

  # if you added more than 50 lines in models in the PR
  files.added_lines(50) do
    check(:some_check)
  end
end
```

It's also possible to add general-purpose rules that get triggered on every pull request open, regardless of files changed:

```
pr_rule :design_thumb, 
  "Design Thumb - If there are significant UI changes, did you get a design thumb?"
```

