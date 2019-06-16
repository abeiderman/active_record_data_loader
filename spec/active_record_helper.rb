# frozen_string_literal: true

require "sqlite3"

class ActiveRecordHelper
  class << self
    def define_schema
      ActiveRecord::Schema.define do
        if ActiveRecordHelper.postgres?
          ActiveRecord::Base.connection.execute(<<~SQL)
            DROP TYPE IF EXISTS order_kinds CASCADE;
            CREATE TYPE order_kinds AS ENUM ('store', 'phone', 'mail', 'web');
          SQL
        end

        create_table :companies, force: true do |t|
          t.text :name

          t.timestamps
        end

        create_table :customers, force: true do |t|
          t.text :name
          t.text :company_name
          t.text :business_name

          t.timestamps
        end

        create_table :employees, force: true do |t|
          t.text :name
          t.text :first_name
          t.text :middle_name
          t.text :last_name
          t.integer :default_int
          t.integer :large_int, limit: 8
          t.integer :medium_int, limit: 4
          t.integer :small_int, limit: 2

          t.timestamps
        end

        create_table :orders, force: true do |t|
          t.text :name
          t.string :code, limit: 12
          t.date :date
          t.integer :order_number
          t.decimal :amount
          t.text :person_type
          t.integer :person_id
          if ActiveRecordHelper.postgres?
            t.column :order_kind, :order_kinds
          else
            t.text :order_kind
          end
          t.text :notes

          t.timestamps
        end

        create_table :payments, force: true do |t|
          t.integer :order_id
          t.date :date
          t.text :method
          t.decimal :amount

          t.timestamps
        end
      end

      reset_column_information
    end

    def postgres?
      ActiveRecord::Base.connection.adapter_name.downcase.to_sym == :postgresql
    end

    def connect_to_postgres
      ActiveRecord::Base.establish_connection(db_config["postgres"])
    end

    def connect_to_sqlite3
      ActiveRecord::Base.establish_connection(db_config["sqlite3"])
    end

    def reset_column_information
      [Customer, Employee, Order, Payment].each(&:reset_column_information)
    end

    def db_config
      @db_config ||= YAML.load_file(File.join(__dir__, "../config/database.yml"))
    end
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Company < ApplicationRecord
end

class Customer < ApplicationRecord
end

class Employee < ApplicationRecord
end

class Order < ApplicationRecord
  belongs_to :person, polymorphic: true
end

class Payment < ApplicationRecord
  belongs_to :order
end
