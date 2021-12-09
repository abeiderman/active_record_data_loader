# frozen_string_literal: true

require "fileutils"
require "securerandom"

RSpec.describe ActiveRecordDataLoader, :connects_to_db do
  let(:loader) do
    ActiveRecordDataLoader.define do
      date_range = (Date.new(2016, 1, 1)..Date.current).to_a.freeze

      model Company do |m|
        m.count 10
      end

      model Customer do |m|
        m.count 100
        m.column :business_name, -> { %w[Acme Initech].sample }
      end

      model Employee do |m|
        m.count 100
      end

      model Order do |m|
        m.batch_size 500
        m.count 1_000
        m.column :date, -> { date_range.sample }

        m.polymorphic :person do |p|
          p.model Customer, weight: 100, eligible_set: -> { Customer.where(business_name: "Acme") }
          p.model Employee, weight: 1
        end
      end

      model Payment do |m|
        m.batch_size 100
        m.count 1_000

        m.column :date, -> { date_range.sample }
        m.belongs_to :order, eligible_set: -> { Order.where(order_kind: "web") }
      end
    end
  end

  context "when there is no file output" do
    shared_examples_for "loading data" do |adapter|
      it "loads data into #{adapter}", adapter do
        loader.load_data

        expect(Company.all).to have(10).items
        expect(Company.all.pluck(:created_at)).to all(be_within(10.minutes).of(Time.now))
        expect(Company.all.pluck(:updated_at)).to all(be_within(10.minutes).of(Time.now))
        expect(Customer.all).to have(100).items
        expect(Employee.all).to have(100).items
        expect(Order.all).to have(1_000).items
        expect(Payment.all).to have(1_000).items
        expect(Order.where(person_type: "Customer").count).to be_between(985, 995)
        expect(Order.where(person_type: "Employee").count).to be_between(5, 15)
        expect(
          Customer.where(
            id: Order.where(person_type: "Customer").pluck(:person_id)
          ).pluck(:business_name).uniq
        ).to eq(["Acme"])
      end
    end

    it_behaves_like "loading data", :sqlite3
    it_behaves_like "loading data", :postgres
    it_behaves_like "loading data", :mysql

    it "uses an optional connection factory" do
      factory = -> { ::ActiveRecord::Base.connection }
      allow(factory).to receive(:call).and_call_original
      config = ActiveRecordDataLoader::Configuration.new(
        logger: ::ActiveRecord::Base.logger,
        connection_factory: factory
      )
      loader = ActiveRecordDataLoader.define(config) do
        model Company do |m|
          m.count 10
        end
      end

      loader.load_data

      expect(Company.all).to have(10).items
      expect(factory).to have_received(:call).at_least(:once)
    end
  end

  context "when there is a file output" do
    def clean_files
      FileUtils.rm(Dir.glob("./#{file_prefix}*"), force: true)
    end

    let(:file_prefix) { "file_output_test_#{SecureRandom.alphanumeric(8)}" }
    let(:filename) { "./#{file_prefix}.sql" }
    after { clean_files }

    shared_examples_for "loading data and writing SQL commands to a file" do |adapter, block|
      it "wirtes SQL commands for #{adapter} into a file", adapter do
        ActiveRecordDataLoader.configure do |c|
          c.logger = ::ActiveRecord::Base.logger
          c.output = filename
        end

        loader.load_data

        expect(Company.all).to have(10).items
        expect(Company.all.pluck(:created_at)).to all(be_within(10.minutes).of(Time.now))
        expect(Company.all.pluck(:updated_at)).to all(be_within(10.minutes).of(Time.now))
        expect(Customer.all).to have(100).items
        expect(Employee.all).to have(100).items
        expect(Order.all).to have(1_000).items
        expect(Payment.all).to have(1_000).items
        expect(Order.where(person_type: "Customer").count).to be_between(985, 995)
        expect(Order.where(person_type: "Employee").count).to be_between(5, 15)

        ActiveRecordHelper.define_schema
        expect(Company.all).to be_empty
        expect(Customer.all).to be_empty
        expect(Employee.all).to be_empty
        expect(Order.all).to be_empty
        expect(Payment.all).to be_empty

        block.call(filename)

        expect(Company.all).to have(10).items
        expect(Company.all.pluck(:created_at)).to all(be_within(10.minutes).of(Time.now))
        expect(Company.all.pluck(:updated_at)).to all(be_within(10.minutes).of(Time.now))
        expect(Customer.all).to have(100).items
        expect(Employee.all).to have(100).items
        expect(Order.all).to have(1_000).items
        expect(Payment.all).to have(1_000).items
        expect(Order.where(person_type: "Customer").count).to be_between(985, 995)
        expect(Order.where(person_type: "Employee").count).to be_between(5, 15)
      end
    end

    it_behaves_like "loading data and writing SQL commands to a file", :postgres, lambda { |f|
      `PGPASSWORD=test psql -h localhost -p 2345 -U test -f #{f}`
    }
    it_behaves_like "loading data and writing SQL commands to a file", :mysql, lambda { |f|
      File.read(f).split("\n").each { |line| ::ActiveRecord::Base.connection.execute(line) }
    }
    it_behaves_like "loading data and writing SQL commands to a file", :sqlite3, lambda { |f|
      File.read(f).split("\n").each { |line| ::ActiveRecord::Base.connection.execute(line) }
    }

    it "sets the statement timeout for postgres scripts", :postgres do
      ActiveRecordDataLoader.configure do |c|
        c.logger = ::ActiveRecord::Base.logger
        c.output = filename
        c.statement_timeout = "10min"
      end

      loader.load_data

      first_script_line = File.open(filename, &:readline)
      last_script_line = File.readlines(filename)[-1]
      expect(first_script_line).to match(/SET.*statement_timeout.*10min/i)
      expect(last_script_line).to match(/RESET.*statement_timeout/i)
    end

    it "truncates the existing SQL script file if it exists", :sqlite3 do
      File.open(filename, "w") { |f| f.puts "This is an existing line" }

      ActiveRecordDataLoader.configure do |c|
        c.logger = ::ActiveRecord::Base.logger
        c.output = filename
      end

      loader.load_data

      first_script_line = File.open(filename, &:readline)
      expect(first_script_line).to match(/\AINSERT/i)
    end
  end

  describe "unique constraints handling" do
    let(:date_range) { (Date.current - 4.days)..Date.current }
    let(:config) { ActiveRecordDataLoader::Configuration.new(logger: ::ActiveRecord::Base.logger) }
    let(:loader) do
      dates = date_range.to_a.freeze
      ActiveRecordDataLoader.define(config) do
        model Customer do |m|
          m.count 100
        end

        model Employee do |m|
          m.count 100
        end

        model Shipment do |m|
          m.count 1_000

          m.column :date, -> { dates.sample }
          m.belongs_to :customer
        end

        model LicenseAgreement do |m|
          m.count 200

          m.column :agreement, true
          m.polymorphic :person do |p|
            p.model Customer
            p.model Employee
          end
        end
      end
    end

    shared_examples_for "handling unique constraints" do |adapter|
      context "when configured to ignore duplicates" do
        it "creates as many unique rows as possible and skips duplicates for #{adapter}", adapter do
          ActiveRecordHelper.reset_pk_sequence(Customer, 100)
          ActiveRecordHelper.reset_pk_sequence(Employee, 1_000)

          loader.load_data

          expect(Customer.all).to have(100).items
          expect(Employee.all).to have(100).items
          # There are 5 dates and 100 customers, so only 500 possible unique values
          expect(Shipment.all).to have(500).items
          expect(LicenseAgreement.all).to have(200).items
          expect(LicenseAgreement.joins(<<~SQL)).to have(100).items
            INNER JOIN customers ON customers.id = person_id AND person_type = 'Customer'
          SQL
          expect(LicenseAgreement.joins(<<~SQL)).to have(100).items
            INNER JOIN employees ON employees.id = person_id AND person_type = 'Employee'
          SQL
        end
      end

      context "when configured to raise on duplicates" do
        let(:loader) do
          dates = date_range.to_a.freeze
          ActiveRecordDataLoader.define(config) do
            model Customer do |m|
              m.count 100
            end

            model Employee do |m|
              m.count 100
            end

            model Shipment do |m|
              m.count 1_000
              m.raise_on_duplicates
              m.max_duplicate_retries 5

              m.column :date, -> { dates.sample }
              m.belongs_to :customer
            end

            model LicenseAgreement do |m|
              m.count 200

              m.column :agreement, true
              m.polymorphic :person do |p|
                p.model Customer
                p.model Employee
              end
            end
          end
        end

        it "raises an error when it runs into duplicates for #{adapter}", adapter do
          expect { loader.load_data }.to raise_error(/duplicate/)
        end
      end
    end

    it_behaves_like "handling unique constraints", :sqlite3
    it_behaves_like "handling unique constraints", :postgres
    it_behaves_like "handling unique constraints", :mysql
  end
end
