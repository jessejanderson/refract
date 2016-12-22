# Refract

Visual diffing in your development environment.

## Installation

```ruby
gem 'refract'
```

## Usage

- define a run in `snapshots.rb`

```
$ refract serve
```

## Development

- Trying out the server
  - Enter a project to test on: `$ cd ~/code/my_rails_app`
  - Run the `refract` script from this codebase: `$ ~/code/refract/bin/refract serve`
  - Visit `http://localhost:7777`
- Running the tests
 - HA HA HA. There are no tests. None.

## TODO

- Make the log come back to the browser
- Handle diffing from different scripts (eg different dimensions)
- More fine-grained percentage (more decimals)
- Full height screenshot
- figure out when refract was run

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
