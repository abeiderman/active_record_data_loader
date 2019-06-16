# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::ActiveRecord::ColumnConfiguration, :connects_to_db do
  let(:model_class) { Order }
  let(:config) do
    ActiveRecordDataLoader::ActiveRecord::ColumnConfiguration.config_for(
      model_class: model_class,
      ar_column: ar_column
    )
  end

  context "when the column is an integer" do
    let(:ar_column) { Order.columns_hash["order_number"] }

    it "returns a config with a generator" do
      expect(config.keys).to eq([:order_number])
      expect(config[:order_number].call).to be_integer
    end
  end

  context "when the column is text" do
    let(:ar_column) { Order.columns_hash["name"] }

    it "returns a config with a generator" do
      expect(config.keys).to eq([:name])
      expect(config[:name].call).to be_a(String)
    end
  end

  context "when the column is a string" do
    let(:ar_column) { Order.columns_hash["code"] }

    it "returns a config with a generator" do
      expect(config.keys).to eq([:code])
      expect(config[:code].call).to be_a(String)
    end
  end

  context "when the column is an enum" do
    let(:ar_column) { Order.columns_hash["order_kind"] }

    it "returns a config with a generator" do
      expect(config.keys).to eq([:order_kind])
      expect(%w[store phone mail web]).to include(config[:order_kind].call)
    end
  end

  context "when the column is a datetime" do
    let(:ar_column) { Order.columns_hash["created_at"] }

    it "returns a config with a generator" do
      expect(config.keys).to eq([:created_at])
      expect(config[:created_at].call(0)).to be_a(Time)
    end
  end
end
