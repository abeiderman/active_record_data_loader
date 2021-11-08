# frozen_string_literal: true

module ActiveRecordDataLoader
  class ConnectionOutputAdapter
    def copy(connection:, table:, columns:, data:)
      raw_connection = connection.raw_connection
      raw_connection.copy_data("COPY #{table} (#{columns}) FROM STDIN WITH (FORMAT CSV)") do
        raw_connection.put_copy_data(data.join("\n"))
      end
    end

    def insert(connection:, command:)
      connection.insert(command)
    end
  end
end
