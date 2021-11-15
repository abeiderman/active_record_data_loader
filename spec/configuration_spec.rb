# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::Configuration do
  describe "#output" do
    it "raises if given a symbol" do
      expect { ActiveRecordDataLoader::Configuration.new(output: :something_else) }
        .to raise_error(/output configuration/i)
      expect { ActiveRecordDataLoader.configuration.output = :something_else }
        .to raise_error(/output configuration/i)
    end

    it "raises if given a hash" do
      expect { ActiveRecordDataLoader::Configuration.new(output: {}) }
        .to raise_error(/output configuration/i)
      expect { ActiveRecordDataLoader.configuration.output = { file: "file.sql" } }
        .to raise_error(/output configuration/i)
    end

    it "remains nil if given nil" do
      config = ActiveRecordDataLoader::Configuration.new(output: nil)

      expect(config.output).to be_nil
    end

    context "when given a string" do
      it "accepts the string as a filename" do
        config = ActiveRecordDataLoader::Configuration.new(
          output: "file.sql"
        )

        expect(config.output).to eq("file.sql")
      end

      it "assigns nil if it is empty" do
        expect(ActiveRecordDataLoader::Configuration.new(output: "").output).to be_nil
        expect(ActiveRecordDataLoader::Configuration.new(output: "    ").output).to be_nil
        expect(ActiveRecordDataLoader::Configuration.new(output: "\n").output).to be_nil
      end
    end
  end
end
