# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::ActiveRecord::PerRowValueCache do
  after do
    described_class.clear
  end

  describe ".[]" do
    it "creates a cache and returns the same cache on subsequent calls" do
      cache1 = described_class[:cache_one]
      cache2 = described_class[:cache_two]

      expect(described_class[:cache_one]).to be(cache1)
      expect(described_class[:cache_one]).to_not be(cache2)
      expect(described_class[:cache_two]).to be(cache2)
      expect(described_class[:cache_two]).to_not be(cache1)
    end
  end

  describe "#get_or_set" do
    let(:cache) { described_class[:test_cache] }

    it "executes the given block when it is not already cached" do
      dummy = double(block_executed: "cached_value")

      value = cache.get_or_set(model: Employee, row: 0) do
        dummy.block_executed
      end

      expect(dummy).to have_received(:block_executed)
      expect(value).to eq("cached_value")
    end

    it "does not execute the block once it has been cached" do
      cache.get_or_set(model: Employee, row: 0) { "original_cached_value" }
      dummy = double(block_executed: "cached_value")

      value = cache.get_or_set(model: Employee, row: 0) do
        dummy.block_executed
      end

      expect(dummy).to_not have_received(:block_executed)
      expect(value).to eq("original_cached_value")
    end

    it "executes the block again for a different model" do
      cache.get_or_set(model: Employee, row: 0) { "Employee value" }
      dummy = double(block_executed: "Order value")

      value = cache.get_or_set(model: Order, row: 0) do
        dummy.block_executed
      end

      expect(dummy).to have_received(:block_executed)
      expect(value).to eq("Order value")
    end

    it "executes the block again for a different row" do
      cache.get_or_set(model: Employee, row: 0) { "Row 0 value" }
      dummy = double(block_executed: "Row 1 value")

      value = cache.get_or_set(model: Employee, row: 1) do
        dummy.block_executed
      end

      expect(dummy).to have_received(:block_executed)
      expect(value).to eq("Row 1 value")
    end

    it "clears previous rows" do
      cache.get_or_set(model: Employee, row: 0) { "Row 0 value" }
      cache.get_or_set(model: Employee, row: 1) { "Row 1 value" }
      dummy = double(block_executed: "Row 0 value again")

      value = cache.get_or_set(model: Employee, row: 0) do
        dummy.block_executed
      end

      expect(dummy).to have_received(:block_executed)
      expect(value).to eq("Row 0 value again")
    end
  end
end
