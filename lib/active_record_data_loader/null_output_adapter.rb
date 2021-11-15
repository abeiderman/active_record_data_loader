# frozen_string_literal: true

module ActiveRecordDataLoader
  class NullOutputAdapter
    def self.with_output_options(_options)
      yield new
    end

    def copy(table:, columns:, data:, row_numbers:); end

    def insert(command); end

    def write_command(command); end
  end
end
