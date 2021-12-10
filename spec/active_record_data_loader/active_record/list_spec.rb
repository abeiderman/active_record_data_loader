# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::ActiveRecord::List do
  describe "random_cycle strategy" do
    let(:source_list) { (1..20).to_a }

    it "cycles through all the items in the list in random order" do
      cycle = described_class.for(source_list, strategy: :random_cycle)

      result_list = 20.times.map { cycle.next }

      expect(result_list).to_not eq(source_list)
      expect(result_list).to match_array(source_list)
    end

    it "shuffles the list after reaching the end of a full iteration" do
      cycle = described_class.for(source_list, strategy: :random_cycle)

      first_list = 20.times.map { cycle.next }
      second_list = 20.times.map { cycle.next }
      third_list = 20.times.map { cycle.next }

      expect(first_list).to_not eq(source_list)
      expect(second_list).to_not eq(first_list)
      expect(third_list).to_not eq(second_list)
      expect(first_list).to match_array(source_list)
      expect(second_list).to match_array(source_list)
      expect(third_list).to match_array(source_list)
    end
  end
end
