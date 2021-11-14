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

  context "when the output is the connection" do
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
      dbl = double(connection_requested: ::ActiveRecord::Base.connection)
      config = ActiveRecordDataLoader::Configuration.new(
        logger: ::ActiveRecord::Base.logger,
        connection_factory: -> { dbl.connection_requested }
      )
      loader = ActiveRecordDataLoader.define(config) do
        model Company do |m|
          m.count 10
        end
      end

      loader.load_data

      expect(Company.all).to have(10).items
      expect(dbl).to have_received(:connection_requested).at_least(:once)
    end
  end

  context "when the output is a file" do
    def clean_files
      FileUtils.rm(Dir.glob("./#{file_prefix}*"), force: true)
    end

    let(:file_prefix) { "file_output_test_#{SecureRandom.alphanumeric(8)}" }
    let(:filename) { "./#{file_prefix}.sql" }
    after { clean_files }

    shared_examples_for "writing SQL commands to a stream" do |adapter, block|
      it "wirtes SQL commands for #{adapter} into a stream", adapter do
        ActiveRecordDataLoader.configure do |c|
          c.logger = ::ActiveRecord::Base.logger
          c.output = { type: :file, filename: filename }
        end

        loader.load_data

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

    it_behaves_like "writing SQL commands to a stream", :postgres, lambda { |f|
      `PGPASSWORD=test psql -h localhost -p 2345 -U test -f #{f}`
    }
    it_behaves_like "writing SQL commands to a stream", :mysql, lambda { |f|
      File.read(f).split("\n").each { |line| ::ActiveRecord::Base.connection.execute(line) }
    }
    it_behaves_like "writing SQL commands to a stream", :sqlite3, lambda { |f|
      File.read(f).split("\n").each { |line| ::ActiveRecord::Base.connection.execute(line) }
    }

    it "sets the statement timeout for postgres scripts", :postgres do
      ActiveRecordDataLoader.configure do |c|
        c.logger = ::ActiveRecord::Base.logger
        c.output = { type: :file, filename: filename }
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
        c.output = { type: :file, filename: filename }
      end

      loader.load_data

      first_script_line = File.open(filename, &:readline)
      expect(first_script_line).to match(/\AINSERT/i)
    end
  end
end
