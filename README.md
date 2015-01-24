# CRDTs for Ruby

This gem provides CRDTs for use in other projects. I've favored clarity of code and intent over optimizations, so if you really need the extra performance, you can use these as a guide to understand the underlying concept, and then implement a more performant version.

That means no fancy class hierarchy, no performance oriented code, no complex loading path and class space munging.

## What are CRDTs

CRDTS are distributed data types that exhibit something called Strong Eventual Consistency. Basically, they're the building blocks that let you build distributed systems.

## How can I learn more

Marc Shapiro has cowritten a bunch of papers that cover both the basics of CRDTs and also a useful survey of simple CRDTs. There are video lectures where he explains most of them visually as well.

In fact, the names of the data types in this project I've taken from his survey paper.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'crdt'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install crdt

## Usage

You can require all the CRDTs, or individual ones:

```ruby
require 'crdt'
```

Or

```ruby
require 'crdt/or_set'
```

## Contributing

1. Fork it ( https://github.com/stevenkaras/crdt/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Acknowledgements

Based on research by Marc Shapiro, et al.

Inspired by [aphyr/meangirls](https://github.com/aphyr/meangirls), but not based on (he does some funky class inheritence/loading tricks I don't like).
