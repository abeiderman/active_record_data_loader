# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::ActiveRecord::ModelDataGenerator, :connects_to_db do
  let(:column_settings) { {} }
  let(:polymorphic_settings) { [] }
  let(:belongs_to_settings) { [] }
  let(:model) { Employee }
  subject(:generator) do
    described_class.new(
      model: model,
      column_settings: column_settings,
      polymorphic_settings: polymorphic_settings,
      belongs_to_settings: belongs_to_settings
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
  end
end
