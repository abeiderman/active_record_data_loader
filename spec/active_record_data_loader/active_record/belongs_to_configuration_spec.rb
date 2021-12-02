# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::ActiveRecord::BelongsToConfiguration, :connects_to_db do
  subject(:config) do
    ActiveRecordDataLoader::ActiveRecord::BelongsToConfiguration.config_for(ar_association: ar_association)
  end

  context "when it is a non-polymorphic belongs_to association" do
    let(:ar_association) { Payment.reflect_on_association("order") }

    it "returns a hash of the column name to the value generator" do
      order = Order.create!

      expect(config.keys).to eq([:order_id])
      expect(config[:order_id].call).to eq(order.id)
    end

    it "samples the primary key of the associated model by default" do
      10.times { Order.create! }
      ids = Order.all.pluck(:id)

      generated_ids = 100.times.map { config[:order_id].call }.uniq

      expect(generated_ids).to have_at_least(2).items
      expect(ids).to include(*generated_ids)
    end

    it "cycles through the primary key values if given a :cycle strategy" do
      10.times { Order.create! }
      ids = Order.all.pluck(:id)
      config = ActiveRecordDataLoader::ActiveRecord::BelongsToConfiguration.config_for(
        ar_association: ar_association,
        strategy: :cycle
      )

      generated_ids = 10.times.map { config[:order_id].call }.uniq

      expect(generated_ids).to match_array(ids)
    end

    it "uses the provided query when not nil" do
      config = ActiveRecordDataLoader::ActiveRecord::BelongsToConfiguration.config_for(
        ar_association: ar_association,
        query: -> { Order.where(order_kind: "web") }
      )
      10.times { Order.create!(order_kind: "phone") }
      web_order = Order.create!(order_kind: "web")

      generated_ids = 100.times.map { config[:order_id].call }.uniq

      expect(generated_ids).to eq([web_order.id])
    end

    it "caches the IDs from the association" do
      10.times { Order.create! }
      allow(Order).to receive(:all).and_call_original

      generator = config[:order_id]
      generator.call
      generator.call

      expect(Order).to have_received(:all).once
    end

    it "clears the cache when retrieving another config set" do
      Order.create!(id: 1)
      first_config = ActiveRecordDataLoader::ActiveRecord::BelongsToConfiguration.config_for(
        ar_association: ar_association
      )
      first_generated_id = first_config[:order_id].call

      Order.find(1).delete
      Order.create!(id: 2)
      second_config = ActiveRecordDataLoader::ActiveRecord::BelongsToConfiguration.config_for(
        ar_association: ar_association
      )
      second_generated_id = second_config[:order_id].call

      expect(first_generated_id).to eq(1)
      expect(second_generated_id).to eq(2)
    end

    it "waits until the generator is called to cache the IDs" do
      generator = config[:order_id]

      order = Order.create!
      id = generator.call

      expect(id).to eq(order.id)
    end
  end

  context "when it is a polymorphic belongs_to association" do
    let(:ar_association) { Order.reflect_on_association("person") }

    it "raises an error" do
      expect { config }.to raise_error(/polymorphic/i)
    end
  end
end
