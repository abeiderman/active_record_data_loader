# active_record_data_loader

[![Build Status](https://github.com/abeiderman/active_record_data_loader/actions/workflows/build.yml/badge.svg)](https://github.com/abeiderman/active_record_data_loader/actions/workflows/build.yml)
[![Coverage Status](https://coveralls.io/repos/github/abeiderman/active_record_data_loader/badge.svg?branch=master&service=github)](https://coveralls.io/github/abeiderman/active_record_data_loader?branch=master)
[![Maintainability](https://api.codeclimate.com/v1/badges/338904b3f7e8d19a3cb1/maintainability)](https://codeclimate.com/github/abeiderman/active_record_data_loader/maintainability)

Efficiently bulk load data for your ActiveRecord models with a simple DSL.

## Why?

Load, performance, and stress tests often require setting up a realistic amount of data in your database. This gem is intended to help organize that data load and make it more maintainable than having a collection of SQL scripts.

#### How is this different from using _factory_bot_?

This gem is not a replacement for [factory_bot](https://github.com/thoughtbot/factory_bot). It solves a different use case. While _factory_bot_ is great for organizing test data and reducing duplication in your functional tests, _active_record_data_loader_ is focused around bulk loading data for performance tests. The purpose of _active_record_data_loader_ is loading large amounts of data as efficiently as possible while providing a DSL that helps with maintainability.

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
    m.column :country, -> { %w[CAN MEX USA].sample }
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

### Unique indexes

Unique indexes will be detected automatically and the data generator will attempt to generate unique values for each row. The generator keeps track of unique values previously generated and retries rows with repeating values. Because some columns could be generating random values, retrying can eventually be successful.

There are a couple of behaviors you can control regarding preventing duplicates. The first is the number of times to retry a given row with duplicate values (that would fail the unique index/constraint). The second is what to do if a unique value cannot be generated after the retries are exhausted.

By default, there will be 5 retries per row and the row will be skipped after all retries are unsuccessful. This means fewer rows than requested may end up being populated on that table.

Alternatively, you can choose to raise an error if a unique row cannot be generated. You can also set the number of retries to 0 to not retry at all. If the table in question is a primary target for your testing and will be loaded with a lot of data, you will likely not want to have retries since it could potentially slow down data generation significantly.

Here is how to adjust these settings. Here let's assyme that `daily_notes` has a unique index on both `date` and `person_id`:

```ruby
class Person < ApplicationRecord
end

class DailyNotes < ApplicationRecord
  belongs_to :person
end

data_loader = ActiveRecordDataLoader.define do
  model Person do |m|
    m.count 500
  end

  model DailyNotes do |m|
    m.count 10_000
    m.max_duplicate_retries 10
    m.do_not_raise_on_duplicates

    m.column :date, -> { Date.today - rand(20) }
  end
end

data_loader.load_data
```

In the case above, retrying could be a reasonable choice since the date is generated at random and it's a small number of rows being generated.

If you want to disable retrying duplicates altogether and raise an error to fail fast you can specify it like this:

```ruby
class Person < ApplicationRecord
end

class Skill < ApplicationRecord
end

class SkillRating < ApplicationRecord
  belongs_to :person
  belongs_to :skill
end

data_loader = ActiveRecordDataLoader.define do
  model Person do |m|
    m.count 100_000
  end

  model Skill do |m|
    m.count 100
  end

  model SkillRating do |m|
    m.count 10_000_000
    m.max_duplicate_retries 0
    m.raise_on_duplicates

    m.column :rating, -> { rand(1..10) }
  end
end

data_loader.load_data
```


### Configuration options

You can define global configuration options like this:

```ruby
ActiveRecordDataLoader.configure do |c|
  c.logger = ActiveSupport::Logger.new("my_file.log", level: :debug)
  c.statement_timeout = "5min"
end
```

Or you can create a configuration object for the specific data loader instance rather than globally:

```ruby
config = ActiveRecordDataLoader::Configuration.new(
  c.logger = ActiveSupport::Logger.new("my_file.log", level: :debug)
  c.statement_timeout = "5min"
)
loader = ActiveRecordDataLoader.define(config) do
  model Company do |m|
    m.count 10
  end

  # ... more definitions
end
```

#### statement_timeout

This is currently only used for Postgres connections to adjust the `statement_timeout` value for the connection. The default is `2min`. Depending on the size of the batches you are loading and overall size of the tables you may need to increase this value:

```ruby
ActiveRecordDataLoader.configure do |c|
  c.statement_timeout = "5min"
end
```

#### connection_factory

The `connection_factory` option accepts a lambda that should return a connection object whenever executed. If not specified, the default behavior is to retrieve a connection using `ActiveRecord::Base.connection`. You can configure it like this:

```ruby
ActiveRecordDataLoader.configure do |c|
  c.connection_factory = -> { MyCustomConnectionHandler.open_connection }
end
```

#### output

The `output` option accepts an optional file name to write a SQL script with the data loading statements. This script file can then be executed manually to load the data. This can be helpful if you need to load the same data multiple times. For example if you are profiling different alternatives in your code and you want to see how each performs with a fully loaded database. In that case you would want to have the same data starting point for each alternative you evaluate. By generating the script file, it would be significantly faster to load that data over and over by executing the existing script.

If `output` is nil or empty, no script file will be written.

Example usage:

```ruby
ActiveRecordDataLoader.configure do |c|
  c.output = "./my_script.sql"  # Outputs to the provided file
end
```

When using an output script file with Postgres, the resulting script will have `\COPY` commands which reference CSV files that contain the data batches to be copied. The CSV files will be created along side the SQL script and will have a naming convention of using the table name and the rows range for the given batch. For example `./my_script_customers_1_to_1000.csv`. Each `\COPY` command in the SQL file will reference the corresponding CSV file so all you need to do is execute the SQL file using `psql`:

```bash
psql -h my-db-host -U my_user -f my_script.sql
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/abeiderman/active_record_data_loader. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the _active_record_data_loader_ project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/abeiderman/active_record_data_loader/blob/master/CODE_OF_CONDUCT.md).
