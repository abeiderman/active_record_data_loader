# frozen_string_literal: true

require "ostruct"

RSpec.describe ActiveRecordDataLoader::ActiveRecord::IntegerValueGenerator, :connects_to_db do
  subject(:generator) { described_class.generator_for(model_class: nil, ar_column: ar_column) }

  %i[postgres sqlite3].each do |db|
    context db.to_s, db do
      context "when the column limit is 2 bytes" do
        let(:ar_column) { Employee.columns_hash["small_int"] }

        it "randomizes between 0 and 32767" do
          allow(described_class).to receive(:rand).and_call_original

          expect(generator.call).to be_between(0, 32_767)
          expect(described_class).to have_received(:rand) do |param|
            expect(param).to eq(0..32_767)
          end
        end
      end

      context "when the column limit is 4 bytes" do
        let(:ar_column) { Employee.columns_hash["medium_int"] }

        it "caps the randomization at 1,000,000,000" do
          allow(described_class).to receive(:rand).and_call_original

          expect(generator.call).to be_between(0, 1_000_000_000)
          expect(described_class).to have_received(:rand) do |param|
            expect(param).to eq(0..1_000_000_000)
          end
        end
      end

      context "when the column does not have an explicit limit" do
        let(:ar_column) { Employee.columns_hash["default_int"] }

        it "caps the randomization at 1,000,000,000" do
          allow(described_class).to receive(:rand).and_call_original

          expect(generator.call).to be_between(0, 1_000_000_000)
          expect(described_class).to have_received(:rand) do |param|
            expect(param).to eq(0..1_000_000_000)
          end
        end
      end
    end
  end
end
