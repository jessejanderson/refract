# Refract

Visual diffing in your development environment.

## Installation

```ruby
gem 'refract'
```

## Usage

- define a run in `snapshots.rb`

  ```ruby
  # snapshots.rb
  Refract.run do |run|
    # Specify a Capybara Driver:
    run.driver(:selenium)
    # Snapshots will be taken with each dimension:
    run.dimension(1024, 768)
    run.dimension(320, 568)

    # `session` is a Capybara::Session
    run.before do |session|
      # executed before each script
    end

    run.script do |session|
      # Take a snapshot with this name:
      session.snapshot("Landing Page")
      # click things ...
      session.snapshot("Event Page")
    end

    run.script do |session|
      # ...
    end
  end
  ```

- manage runs in the browser:

  ```
  $ bundle exec refract serve
  ```

- or, run in the terminal:

  ```
  $ bundle exec refract run
  ```

## Development

- Trying out the server
  - Enter a project to test on: `$ cd ~/code/my_rails_app`
  - `gem "refract", path: "~/code/refract"`
  - `bundle exec refract serve`
  - Visit `http://localhost:7777`
- Running the tests
 - HA HA HA. There are no tests. None.

## TODO

- Full height screenshot

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
