# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::Dsl::Definition do
  let(:configuration) do
    ActiveRecordDataLoader::Configuration.new(default_row_count: 50, default_batch_size: 1_000)
  end
  subject(:definition) { described_class.new(configuration) }

  describe "model" do
    it "captures the options given" do
      definition.model(Customer) do |m|
        m.batch_size 10
        m.count 100
        m.column :date, -> { Date.current }
      end

      expect(definition.models).to have(1).item
      model = definition.models.last
      expect(model).to have_attributes(
        klass: Customer,
        batch_size: 10,
        row_count: 100,
        polymorphic_associations: []
      )
      expect(model.columns[:date].call).to eq(Date.current)
    end

    it "defaults the batch size from configuration when not given" do
      definition.model(Customer)

      expect(definition.models).to have(1).item
      model = definition.models.last
      expect(model).to have_attributes(
        batch_size: 1_000,
        row_count: 50
      )
    end

    it "captures polymorphic association configuration" do
      definition.model(Order) do |m|
        m.polymorphic :person do |p|
          p.model Customer, weight: 10
          p.model Employee, weight: 1
        end
      end

      expect(definition.models).to have(1).item
      model = definition.models.last
      expect(model.polymorphic_associations).to have(1).item
      expect(model.polymorphic_associations.last).to have_attributes(
        model_class: Order,
        name: :person,
        models: {
          Customer => 10,
          Employee => 1,
        }
      )
    end

    it "captures a belongs to association with a custom query" do
      query = -> { Order.where(name: "Phone") }

      definition.model(Payment) do |m|
        m.belongs_to :order, eligible_set: query
      end

      expect(definition.models).to have(1).item
      model = definition.models.last
      expect(model.belongs_to_associations).to have(1).item
      expect(model.belongs_to_associations.last).to have_attributes(
        model_class: Payment,
        name: :order,
        query: query
      )
    end

    it "can capture multiple models" do
      definition.model(Company) { |m| m.count 10 }
      definition.model(Customer) { |m| m.count 100 }
      definition.model(Employee)

      expect(definition.models.map(&:klass)).to match_array([Company, Customer, Employee])
    end
  end
end
