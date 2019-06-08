# frozen_string_literal: true

RSpec.describe DataLoader, :connects_to_db do
  describe "DSL" do
    let(:loader) do
      DataLoader.define do
        date_range = (Date.new(2016, 1, 1)..Date.current).to_a.freeze

        model Company do |m|
          m.count 10
        end

        model Customer do |m|
          m.count 100
        end

        model Employee do |m|
          m.count 100
        end

        model Order do |m|
          m.batch_size 500
          m.count 1_000
          m.column :date, -> { date_range.sample }

          m.polymorphic :person do |p|
            p.model Customer, weight: 100
            p.model Employee, weight: 1
          end
        end

        model Payment do |m|
          m.batch_size 100
          m.count 1_000

          m.column :date, -> { date_range.sample }
        end
      end
    end

    it "loads data into sqlite3", :sqlite3 do
      loader.load_data

      expect(Company.all).to have(10).items
      expect(Customer.all).to have(100).items
      expect(Employee.all).to have(100).items
      expect(Order.all).to have(1_000).items
      expect(Payment.all).to have(1_000).items
      expect(Order.where(person_type: "Customer").count).to be_between(985, 995)
      expect(Order.where(person_type: "Employee").count).to be_between(5, 15)
    end

    it "loads data into postgres", :postgres do
      loader.load_data

      expect(Company.all).to have(10).items
      expect(Customer.all).to have(100).items
      expect(Employee.all).to have(100).items
      expect(Order.all).to have(1_000).items
      expect(Payment.all).to have(1_000).items
      expect(Order.where(person_type: "Customer").count).to be_between(985, 995)
      expect(Order.where(person_type: "Employee").count).to be_between(5, 15)
    end
  end
end
