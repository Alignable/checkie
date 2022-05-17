# Setup

1. Create github action
```yml
jobs:
  checkie:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./.github/checkie
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          working-directory: ./.github/checkie
          bundler-cache: false
      - run: bundle install
      - run: bundle exec ruby main.rb $PR_URL $ACTION
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_URL: ${{ github.event.pull_request.url }}
          ACTION: ${{ github.event.action }}
```
2. Create project in `.github/checkie` with Gemfile:
```ruby
gem "checkie", github: 'Alignable/checkie'
```
3. Create main file:
```ruby
require './rules'

# Run from command line with bundle exec ruby main.rb PR_URL ACTION_TYPE
run(ARGV[0].dup, ARGV[1].dup)
```
4. Write rules in that project in `rules.rb`. More info on writing rules in RULES.md example:
```ruby
file_rule :hardcoded_url,
          "Looks like you might have a hardcoded url http:// - should that be an ENV variable?"

matching("app/facades/**.rb") do |changes, files|
  changes.added(/https?\:\/\//) do
    check(:hardcoded_url)
  end
end
```
