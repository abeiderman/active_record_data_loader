# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::Dsl::PolymorphicAssociation do
  describe "#weighted_models" do
    subject(:association) { described_class.new(Order, :person) }

    it "repeats models by weight" do
      association.model(Customer, weight: 5)
      association.model(Employee, weight: 3)

      expect(association.weighted_models).to match_array(
        [
          Customer, Customer, Customer, Customer, Customer,
          Employee, Employee, Employee,
        ]
      )
    end

    it "reduces the weights when there is a common divisor" do
      association.model(Customer, weight: 100)
      association.model(Employee, weight: 20)
      association.model(Payment, weight: 50)

      expect(association.weighted_models).to match_array(
        [
          Customer, Customer, Customer, Customer, Customer,
          Customer, Customer, Customer, Customer, Customer,
          Payment, Payment, Payment, Payment, Payment,
          Employee, Employee,
        ]
      )
    end
  end
end
