# frozen_string_literal: true

module ActiveRecordDataLoader
  class IOStreamOutputAdapter
    def initialize(io_stream)
      @io_stream = io_stream
    end

    def copy(connection:, table:, columns:, data:)
      io_stream.write("COPY #{table} (#{columns}) FROM PROGRAM 'echo ")
      io_stream.write(data.join("\\\\n"))
      io_stream.write("' WITH (FORMAT CSV);\n\n")
    end

    def insert(connection:, command:)
      io_stream.write("#{command.gsub("\n", ' ')};\n")
    end

    private

    attr_reader :io_stream
  end
end
