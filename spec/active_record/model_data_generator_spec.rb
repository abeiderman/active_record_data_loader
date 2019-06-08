# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::ActiveRecord::ModelDataGenerator, :connects_to_db do
  let(:column_settings) { {} }
  let(:polymorphic_settings) { [] }
  let(:model) { Employee }
  subject(:generator) do
    described_class.new(
      model: model,
      column_settings: column_settings,
      polymorphic_settings: polymorphic_settings
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
    end
  end
end
