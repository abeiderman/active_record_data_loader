# frozen_string_literal: true

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
