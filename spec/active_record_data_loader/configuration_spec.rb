# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::Configuration do
  describe "#output" do
    it "raises if given a symbol" do
      expect { described_class.new(output: :something_else) }
        .to raise_error(/output configuration/i)
      expect { ActiveRecordDataLoader.configuration.output = :something_else }
        .to raise_error(/output configuration/i)
    end

    it "raises if given a hash" do
      expect { described_class.new(output: {}) }
        .to raise_error(/output configuration/i)
      expect { ActiveRecordDataLoader.configuration.output = { file: "file.sql" } }
        .to raise_error(/output configuration/i)
    end

    it "remains nil if given nil" do
      config = described_class.new(output: nil)

      expect(config.output).to be_nil
    end

    context "when given a string" do
      it "accepts the string as a filename" do
        config = described_class.new(output: "file.sql")

        expect(config.output).to eq("file.sql")
      end

      it "assigns nil if it is empty" do
        expect(described_class.new(output: "").output).to be_nil
        expect(described_class.new(output: "    ").output).to be_nil
        expect(described_class.new(output: "\n").output).to be_nil
      end
    end
  end

  describe "#max_duplicate_retries" do
    context "when given a lambda" do
      it "executes the given lambda" do
        config = described_class.new(max_duplicate_retries: -> { 10 })

        expect(config.max_duplicate_retries).to eq(10)
      end

      it "executes the lambda with a model argument" do
        config = described_class.new(max_duplicate_retries: ->(model) { model == Customer ? 10 : 20 })

        expect(config.max_duplicate_retries(Customer)).to eq(10)
        expect(config.max_duplicate_retries(Employee)).to eq(20)
      end
    end

    context "when given an integer" do
      it "returns the given value" do
        config = described_class.new(max_duplicate_retries: 10)

        expect(config.max_duplicate_retries).to eq(10)
      end
    end
  end
end
