# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::ActiveRecord::ModelDataGenerator, :connects_to_db do
  let(:column_settings) { {} }
  let(:polymorphic_settings) { [] }
  let(:belongs_to_settings) { [] }
  let(:model) { Employee }
  let(:raise_on_duplicates) { false }
  let(:max_duplicate_retries) { 20 }
  subject(:generator) do
    described_class.new(
      model: model,
      column_settings: column_settings,
      polymorphic_settings: polymorphic_settings,
      belongs_to_settings: belongs_to_settings,
      connection_factory: -> { ActiveRecord::Base.connection },
      raise_on_duplicates: raise_on_duplicates,
      max_duplicate_retries: max_duplicate_retries,
      logger: ActiveRecordDataLoader.configuration.logger
    )
  end

  describe "#generate_row" do
    context "when there are no given column settings" do
      it "auto generates values for each column" do
        row = generator.generate_row(0)

        row_hash = generator.column_list.zip(row).to_h
        expect(row_hash[:name]).to be_a(String)
        expect(row_hash[:name]).to_not be_blank
        expect(row_hash[:first_name]).to be_a(String)
        expect(row_hash[:first_name]).to_not be_blank
        expect(row_hash[:middle_name]).to be_a(String)
        expect(row_hash[:middle_name]).to_not be_blank
        expect(row_hash[:last_name]).to be_a(String)
        expect(row_hash[:last_name]).to_not be_blank
        expect(row_hash[:default_int]).to be_a(Integer)
        expect(row_hash[:large_int]).to be_a(Integer)
        expect(row_hash[:medium_int]).to be_a(Integer)
        expect(row_hash[:small_int]).to be_a(Integer)
        expect(row_hash[:created_at]).to be_within(2.minutes).of(Time.now.utc)
        expect(row_hash[:updated_at]).to be_within(2.minutes).of(Time.now.utc)
      end
    end

    context "when given a column lamba that takes no arguments" do
      let(:column_settings) { { name: -> { "Expected name" } } }

      it "uses the lambda to populate the value" do
        row = generator.generate_row(0)

        row_hash = generator.column_list.zip(row).to_h
        expect(row_hash[:name]).to eq("Expected name")
      end
    end

    context "when given a column lamba that takes one argument" do
      let(:column_settings) { { name: ->(row) { "Name for #{row}" } } }

      it "uses the lambda to populate the value" do
        row = generator.generate_row(0)

        row_hash = generator.column_list.zip(row).to_h
        expect(row_hash[:name]).to eq("Name for 0")
      end
    end

    context "when given a column lamba that takes two arguments" do
      let(:column_settings) { { name: ->(row, col) { "Name for #{row}, #{col}" } } }

      it "uses the lambda to populate the value" do
        row = generator.generate_row(0)

        row_hash = generator.column_list.zip(row).to_h
        expect(row_hash[:name]).to eq("Name for 0, name")
      end
    end

    context "when given a static column value" do
      let(:column_settings) { { name: "Static value" } }

      it "uses the given value" do
        row = generator.generate_row(0)

        row_hash = generator.column_list.zip(row).to_h
        expect(row_hash[:name]).to eq("Static value")
      end
    end

    context "when the model has a belongs_to association" do
      let(:model) { Payment }

      it "populates the foreign key column" do
        Order.create!(id: 10)

        row = generator.generate_row(0)

        row_hash = generator.column_list.zip(row).to_h
        expect(row_hash[:order_id]).to eq(10)
      end

      context "when given belongs_to settings" do
        let(:belongs_to_settings) do
          [
            ActiveRecordDataLoader::Dsl::BelongsToAssociation.new(
              Payment,
              :order,
              -> { Order.where(order_kind: "phone") }
            ),
          ]
        end

        it "uses the provided query to limit the set" do
          10.times { Order.create!(order_kind: "store") }
          phone_order = Order.create!(order_kind: "phone")

          rows = 10.times.map { generator.generate_row(0) }

          row_hashes = rows.map { |r| generator.column_list.zip(r).to_h }
          expect(row_hashes.map { |r| r[:order_id] }.uniq).to eq([phone_order.id])
        end
      end
    end

    context "when the model has a polymorphic belongs_to association" do
      let(:model) { Order }
      let(:polymorphic_settings) do
        [
          ActiveRecordDataLoader::Dsl::PolymorphicAssociation.new(Order, :person).tap do |a|
            a.model(Customer)
          end,
        ]
      end

      it "populates the foreign key and the type columns" do
        Customer.create!(id: 50)

        row = generator.generate_row(0)

        row_hash = generator.column_list.zip(row).to_h
        expect(row_hash[:person_id]).to eq(50)
        expect(row_hash[:person_type]).to eq("Customer")
      end

      context "when given a query for a model" do
        let(:polymorphic_settings) do
          [
            ActiveRecordDataLoader::Dsl::PolymorphicAssociation.new(Order, :person).tap do |a|
              a.model(Customer, eligible_set: -> { Customer.where(business_name: "Initech") })
            end,
          ]
        end

        it "limits the set to the given query" do
          Customer.create!(business_name: "Initech")
          Customer.create!(business_name: "Acme")

          rows = 50.times.map { generator.generate_row(0) }

          row_hashes = rows.map { |r| generator.column_list.zip(r).to_h }
          person_ids = row_hashes.map { |r| r[:person_id] }.uniq
          expect(Customer.where(id: person_ids).pluck(:business_name).uniq).to eq(["Initech"])
        end
      end
    end

    context "when the model has a unique index" do
      let(:model) { Shipment }
      let(:date_range) { (Date.new(2021, 11, 10)..Date.new(2021, 11, 13)).to_a.freeze }
      let(:column_settings) { { date: -> { date_range.sample } } }

      it "does not repeat values if retrying eventually finds unique values" do
        Customer.create!(business_name: "Acme")

        rows = 4.times.map { |i| generator.generate_row(i) }
        row_hashes = rows.map { |r| generator.column_list.zip(r).to_h }
        expect(row_hashes.map { |r| [r[:customer_id], r[:date]] }.uniq).to have(4).items
      end

      it "returns null rows if it can't find unique values by retrying" do
        Customer.create!(business_name: "Acme")

        rows = 6.times.map { |i| generator.generate_row(i) }
        expect(rows).to have(6).items
        expect(rows.compact).to have(4).items
        row_hashes = rows.compact.map { |r| generator.column_list.zip(r).to_h }
        expect(row_hashes.map { |r| [r[:customer_id], r[:date]] }.uniq).to have(4).items
      end

      context "when the unqiue values include two foreign keys" do
        let(:model) { EmployeeSkill }

        it "shuffles the foreign key IDs while cycling so it can eventually produce unique combinations" do
          10.times { Employee.create! }
          5.times { Skill.create! }

          rows = 50.times.map { |i| generator.generate_row(i) }
          row_hashes = rows.compact.map { |r| generator.column_list.zip(r).to_h }
          expect(row_hashes.map { |r| [r[:employee_id], r[:skill_id]] }.uniq).to have_at_least(41).items
          expect(row_hashes.map { |r| r[:employee_id] }.uniq).to have(10).items
          expect(row_hashes.map { |r| r[:skill_id] }.uniq).to have(5).items
        end
      end

      context "when given zero max retries" do
        let(:column_settings) do
          call_count = 0
          {
            date: lambda do
              day = (call_count += 1) > 2 ? 11 : 10
              Date.new(2021, 11, day)
            end,
          }
        end
        let(:max_duplicate_retries) { 0 }

        it "does not retry and returns null rows" do
          Customer.create!(business_name: "Acme")

          rows = 2.times.map { |i| generator.generate_row(i) }
          expect(rows).to have(2).items
          expect(rows.compact).to have(1).item
        end
      end

      context "when configured to raise on duplicates" do
        let(:raise_on_duplicates) { true }

        it "raises if it can't find unique values by retrying" do
          Customer.create!(business_name: "Acme")

          4.times.map { |i| generator.generate_row(i) }
          expect { generator.generate_row(4) }.to raise_error(/duplicate/)
        end
      end

      context "when the unique index is on a polymorphic association" do
        let(:model) { LicenseAgreement }
        let(:column_settings) { {} }
        let(:polymorphic_settings) do
          [
            ActiveRecordDataLoader::Dsl::PolymorphicAssociation.new(LicenseAgreement, :person).tap do |a|
              a.model(Customer)
              a.model(Employee)
            end,
          ]
        end

        it "does not repeat values if retrying eventually finds unique values" do
          Customer.create!(id: 10, business_name: "Acme")
          Customer.create!(id: 20, business_name: "Initech")
          Employee.create!(id: 100)
          Employee.create!(id: 200)

          rows = 4.times.map { |i| generator.generate_row(i) }
          row_hashes = rows.map { |r| generator.column_list.zip(r).to_h }
          expect(row_hashes.map { |r| [r[:person_id], r[:person_type]] }.uniq).to match_array(
            [
              [10, "Customer"],
              [20, "Customer"],
              [100, "Employee"],
              [200, "Employee"],
            ]
          )
        end

        it "returns null rows if it can't find unique values by retrying" do
          Customer.create!(id: 10, business_name: "Acme")
          Customer.create!(id: 20, business_name: "Initech")
          Employee.create!(id: 100)
          Employee.create!(id: 200)

          rows = 6.times.map { |i| generator.generate_row(i) }
          expect(rows).to have(6).items
          expect(rows.compact).to have(4).items
          row_hashes = rows.compact.map { |r| generator.column_list.zip(r).to_h }
          expect(row_hashes.map { |r| [r[:person_id], r[:person_type]] }.uniq).to match_array(
            [
              [10, "Customer"],
              [20, "Customer"],
              [100, "Employee"],
              [200, "Employee"],
            ]
          )
        end
      end
    end
  end
end
