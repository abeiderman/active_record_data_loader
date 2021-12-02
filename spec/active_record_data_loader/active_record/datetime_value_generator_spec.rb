# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::ActiveRecord::DatetimeValueGenerator, :connects_to_db do
  let(:created_at_generator) do
    described_class.generator_for(model_class: Employee, ar_column: Employee.columns_hash["created_at"])
  end
  let(:updated_at_generator) do
    described_class.generator_for(model_class: Employee, ar_column: Employee.columns_hash["updated_at"])
  end

  it "uses the current UTC timestamp" do
    time = Time.new(2019, 6, 10, 10, 30, 20).utc

    Timecop.freeze(time) do
      expect(created_at_generator.call(0)).to eq(time)
      expect(updated_at_generator.call(0)).to eq(time)
    end
  end

  it "returns the same timestamp for created_at and updated_at for a given row" do
    time = Time.new(2019, 6, 10, 10, 30, 20).utc

    Timecop.freeze(time) do
      expect(created_at_generator.call(0)).to eq(time)
    end
    Timecop.freeze(time + 30.seconds) do
      expect(updated_at_generator.call(0)).to eq(time)
    end
  end

  it "returns a different timestamp for subsequent rows" do
    time = Time.new(2019, 6, 10, 10, 30, 20).utc

    Timecop.freeze(time) do
      expect(created_at_generator.call(0)).to eq(time)
    end
    Timecop.freeze(time + 30.seconds) do
      expect(updated_at_generator.call(0)).to eq(time)
      expect(created_at_generator.call(1)).to eq(time + 30.seconds)
    end
  end
end
