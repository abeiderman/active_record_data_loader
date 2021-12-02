# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::ActiveRecord::TextValueGenerator, :connects_to_db do
  let(:model) { Employee }
  let(:generator) { described_class.generator_for(model_class: model, ar_column: ar_column) }
  subject(:value) { generator.call }

  before do
    allow(ActiveRecordDataLoader::DataFaker).to receive(:person_name).and_return("Mary Smith")
    allow(ActiveRecordDataLoader::DataFaker).to receive(:first_name).and_return("Mary")
    allow(ActiveRecordDataLoader::DataFaker).to receive(:middle_name).and_return("Joe")
    allow(ActiveRecordDataLoader::DataFaker).to receive(:last_name).and_return("Smith")
    allow(ActiveRecordDataLoader::DataFaker).to receive(:company_name).and_return("ACME")
  end

  context "when the column name is 'name'" do
    %w[
      Customer
      Human
      Employee
      Person
      User
    ].each do |model_name|
      context "when the model name is '#{model_name}' suggesting it is a person" do
        let(:ar_column) { Employee.columns_hash["name"] }
        let(:model) { double(name: model_name) }

        it { is_expected.to eq("Mary Smith") }
      end
    end

    %w[
      Business
      Company
      Enterprise
      LegalEntity
      Organization
    ].each do |model_name|
      context "when the model name is '#{model_name}' suggesting it is an organization" do
        let(:ar_column) { Employee.columns_hash["name"] }
        let(:model) { double(name: model_name) }

        it { is_expected.to eq("ACME") }
      end
    end
  end

  context "when the column name is first_name" do
    let(:ar_column) { Employee.columns_hash["first_name"] }

    it { is_expected.to eq("Mary") }
  end

  context "when the column name is middle_name" do
    let(:ar_column) { Employee.columns_hash["middle_name"] }

    it { is_expected.to eq("Joe") }
  end

  context "when the column name is last_name" do
    let(:ar_column) { Employee.columns_hash["last_name"] }

    it { is_expected.to eq("Smith") }
  end

  %w[
    company_name
    business_name
  ].each do |column_name|
    context "when the column name is '#{column_name}'" do
      let(:ar_column) { Customer.columns_hash[column_name] }

      it { is_expected.to eq("ACME") }
    end
  end

  context "when the column name is not matched to a special scenario" do
    let(:ar_column) { Order.columns_hash["notes"] }
    let(:model) { Order }

    it "generates a random UUID" do
      allow(SecureRandom).to receive(:uuid).and_return("random-uuid")

      expect(generator.call).to eq("random-uuid")
    end
  end

  context "when the column is a string with a limit" do
    let(:ar_column) { Order.columns_hash["code"] }
    let(:model) { Order }

    it "truncates the random UUID to be under the limit" do
      allow(SecureRandom).to receive(:uuid).and_return("0123456789ABCDEFGHI")

      expect(generator.call).to eq("0123456789AB")
    end
  end
end
