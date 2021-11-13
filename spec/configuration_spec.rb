# frozen_string_literal: true

RSpec.describe ActiveRecordDataLoader::Configuration do
  describe "#output" do
    context "when given a symbol" do
      it "reflects the symbol as the output type in the resulting hash" do
        connection_config = ActiveRecordDataLoader::Configuration.new(output: :connection)
        file_config = ActiveRecordDataLoader::Configuration.new(output: :file)

        expect(connection_config.output).to eq({ type: :connection })
        expect(file_config.output).to eq({ type: :file })
      end

      it "raises if the symbol is not :connection or :file" do
        expect { ActiveRecordDataLoader::Configuration.new(output: :something_else) }
          .to raise_error(/output configuration/i)
        expect { ActiveRecordDataLoader.configuration.output = :something_else }
          .to raise_error(/output configuration/i)
      end
    end

    context "when given a hash" do
      it "selects only the relevant keys for file output" do
        config = ActiveRecordDataLoader::Configuration.new(
          output: { type: :file, filename: "file.sql", location: "/", other: "foo" }
        )

        expect(config.output).to eq({ type: :file, filename: "file.sql" })
      end

      it "selects only the relevant keys for connection output" do
        config = ActiveRecordDataLoader::Configuration.new(
          output: { type: :connection, filename: "file.sql", host: "localhost", other: "foo" }
        )

        expect(config.output).to eq({ type: :connection })
      end

      it "raises if the type is missing" do
        expect { ActiveRecordDataLoader::Configuration.new(output: { kind: :connection }) }
          .to raise_error(/output hash/i)
      end

      it "raises if the type is not :connection or :file" do
        expect { ActiveRecordDataLoader::Configuration.new(output: { type: :other }) }
          .to raise_error(/output hash/i)
      end
    end
  end
end
