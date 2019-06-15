# ActiveRecord Data Loader

[![Build Status](https://travis-ci.org/abeiderman/active_record_data_loader.svg?branch=master)](https://travis-ci.org/abeiderman/active_record_data_loader)
[![Coverage Status](https://coveralls.io/repos/github/abeiderman/active_record_data_loader/badge.svg?branch=master&service=github)](https://coveralls.io/github/abeiderman/active_record_data_loader?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/338904b3f7e8d19a3cb1/maintainability)](https://codeclimate.com/github/abeiderman/active_record_data_loader/maintainability)

Efficiently bulk load data for your ActiveRecord models with a simple DSL.

## Why?

Load, performance, and stress tests often require setting up a realistic amount of data in your database. This gem is intended to help organize that data load and make it more maintainable than having a collection of SQL scripts.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "active_record_data_loader"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_record_data_loader

## Usage

The gem will recognize most commonly used column types and attempt to populate with sensible values by default. You can override this behavior as you will see further below.

`belongs_to` associations are recognized automatically. However, data is loaded in the order you define, so you want to make sure the parent model is loaded first.

Polymorphic associations need to be defined explicitly as shown in [Polymorphic associations](#polymorphic-associations).

### Basic usage

Let's say you have the following models:
```ruby
class Customer < ApplicationRecord
end

class Order < ApplicationRecord
  belongs_to :customer
end
```

The following code will create 10,000 customers and 100,000 orders, and will associate the orders to those customers evenly:
```ruby
data_loader = ActiveRecordDataLoader.define do
  model Customer do |m|
    m.count 10_000
  end

  model Order do |m|
    m.count 100_000
  end
end

data_loader.load_data
```

#### Overriding column values
To provide your own values for columns your can provide a lambda or a constant value:
```ruby
data_loader = ActiveRecordDataLoader.define do
  model Customer do |m|
    m.count 10_000
    m.column :name, -> { %w[Jane John Mary Matt].sample }
    m.column :country, "USA"
    m.column :terminated_at, nil
  end

  ...
end

data_loader.load_data
```

### Controlling associations
Let's say that you have certain restrictions on orders depending on country. You would want to test data to follow those restrictions which means orders cannot be randomly associated to any customer. You can control that by providing an `eligible_set` on the association.

In this example, we are creating 25K orders for customers in CAN with a CAD currency, 25K for customers in MEX with a MXN currency, and 50K for those in USA with a USD currency.

```ruby
data_loader = ActiveRecordDataLoader.define do
  model Customer do |m|
    m.count 10_000
    m.column :country, -> { %w[CAN MXN USA].sample }
  end

  model Order do |m|
    m.count 25_000
    m.column :currency, "CAD"
    m.belongs_to :customer, eligible_set: -> { Customer.where(country: "CAN") }
  end
  
  model Order do |m|
    m.count 25_000
    m.column :currency, "MXN"
    m.belongs_to :customer, eligible_set: -> { Customer.where(country: "MEX") }
  end
  
   model Order do |m|
    m.count 50_000
    m.column :currency, "USD"
    m.belongs_to :customer, eligible_set: -> { Customer.where(country: "USA") }
  end
end

data_loader.load_data
```

### Polymorphic associations

If you have a polymorphic `belongs_to` association, you will need to define that explicitly for it to be populated.

Let's assume the following models where an order could belong to either a person or a business:
```ruby
class Person < ApplicationRecord
  has_many :orders
end

class Business < ApplicationRecord
  has_many :orders
end

class Order < ApplicationRecord
  belongs_to :customer, polymorphic: true
end
```

In order to populate the `customer` association in orders, you would specify them like this:
```ruby
data_loader = ActiveRecordDataLoader.define do
  model Person do |m|
    m.count 5_000
  end

  model Business do |m|
    m.count 5_000
  end

  model Order do |m|
    m.count 100_000
    
    m.polymorphic :customer do |c|
      c.model Person
      c.model Business
    end
  end
end

data_loader.load_data
```

You can also provide a `weight` to each of the target models if you want to control how they are distributed. If you wanted to have twice as many orders for `Person` than for `Business`, it would look like this:
```ruby
data_loader = ActiveRecordDataLoader.define do
  model Person do |m|
    m.count 5_000
  end

  model Business do |m|
    m.count 5_000
  end

  model Order do |m|
    m.count 100_000
    
    m.polymorphic :customer do |c|
      c.model Person, weight: 2
      c.model Business, weight: 1
    end
  end
end

data_loader.load_data
```

Additionaly, you can also provide an `eligible_set` to control which records to limit the association to:
```ruby
data_loader = ActiveRecordDataLoader.define do
  model Person do |m|
    m.count 5_000
  end

  model Business do |m|
    m.count 5_000
    m.column :country, -> { %w[CAN USA].sample }
  end

  model Order do |m|
    m.count 100_000
    
    m.polymorphic :customer do |c|
      c.model Person, weight: 2
      c.model Business, weight: 1, eligible_set: -> { Business.where(country: "USA") }
    end
  end
end

data_loader.load_data
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/abeiderman/active_record_data_loader. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ActiveRecord Data Loader project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/abeiderman/active_record_data_loader/blob/master/CODE_OF_CONDUCT.md).
