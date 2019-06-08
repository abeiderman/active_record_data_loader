# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::ActiveRecord::EnumValueGenerator, :connects_to_db do
  subject(:generator) { described_class.generator_for(model_class: Order, ar_column: ar_column) }

  context "when it is a postgres enum", :postgres do
    let(:ar_column) { Order.columns_hash["order_kind"] }

    it "randomly chooses one of the enum values" do
      value = generator.call

      expect(%w[store phone mail web]).to include(value)
    end
  end
end
