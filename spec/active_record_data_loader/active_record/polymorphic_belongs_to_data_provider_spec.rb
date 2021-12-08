# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::ActiveRecord::PolymorphicBelongsToDataProvider, :connects_to_db do
  subject(:config) do
    described_class.provider_for(
      polymorphic_settings: settings
    )
  end

  context "when it is a polymorphic belongs_to association" do
    let(:settings) do
      ActiveRecordDataLoader::Dsl::PolymorphicAssociation.new(Order, :person).tap do |a|
        a.model(Customer)
        a.model(Employee)
      end
    end

    it "returns a hash of the type and id columns" do
      Customer.create!(id: 10)
      Employee.create!(id: 20)

      expect(config.keys).to match_array([:person_type, :person_id])
      expect(config[:person_type].call(0)).to eq("Customer")
      expect(config[:person_id].call(0)).to eq(10)
      expect(config[:person_type].call(1)).to eq("Employee")
      expect(config[:person_id].call(1)).to eq(20)
    end

    it "samples the primary key of the associated models" do
      100.times do |i|
        Customer.create!(id: 10 + i)
        Employee.create!(id: 10_000 + i)
      end
      customer_ids = Customer.all.pluck(:id)
      employee_ids = Employee.all.pluck(:id)

      generated_customer_ids = 100.times.map { config[:person_id].call(0) }.uniq
      generated_employee_ids = 100.times.map { config[:person_id].call(1) }.uniq

      expect(generated_customer_ids).to have_at_least(2).items
      expect(generated_employee_ids).to have_at_least(2).items
      expect(customer_ids).to include(*generated_customer_ids)
      expect(employee_ids).to include(*generated_employee_ids)
    end

    it "cycles through the primary key values if given a :cycle strategy" do
      100.times do |i|
        Customer.create!(id: 10 + i)
        Employee.create!(id: 10_000 + i)
      end
      customer_ids = Customer.order(:id).pluck(:id)
      employee_ids = Employee.order(:id).pluck(:id)

      config = described_class.provider_for(
        polymorphic_settings: settings,
        strategy: :cycle
      )
      generated_customer_ids = 100.times.map { config[:person_id].call(0) }.uniq
      generated_employee_ids = 100.times.map { config[:person_id].call(1) }.uniq

      expect(generated_customer_ids).to match_array(customer_ids)
      expect(generated_employee_ids).to match_array(employee_ids)
    end

    it "caches the IDs from the association" do
      10.times { Customer.create! }
      10.times { Employee.create! }
      allow(Customer).to receive(:all).and_call_original
      allow(Employee).to receive(:all).and_call_original

      generator = config[:person_id]
      3.times do
        generator.call(0)
        generator.call(1)
      end

      expect(Customer).to have_received(:all).once
      expect(Employee).to have_received(:all).once
    end

    it "clears the cache when retrieving another config set" do
      Customer.create!(id: 1)
      first_config = described_class.provider_for(
        polymorphic_settings: settings
      )
      first_generated_id = first_config[:person_id].call(0)

      Customer.find(1).delete
      Customer.create!(id: 2)
      second_config = described_class.provider_for(
        polymorphic_settings: settings
      )
      second_generated_id = second_config[:person_id].call(0)

      expect(first_generated_id).to eq(1)
      expect(second_generated_id).to eq(2)
    end

    it "waits until the generator is called to cache the IDs" do
      generator = config[:person_id]

      customer = Customer.create!
      id = generator.call(0)

      expect(id).to eq(customer.id)
    end
  end

  context "when it is a non-polymorphic belongs_to association" do
    let(:settings) do
      ActiveRecordDataLoader::Dsl::PolymorphicAssociation.new(Payment, :order)
    end

    it "raises an error" do
      expect { config }.to raise_error(/polymorphic/i)
    end
  end
end
