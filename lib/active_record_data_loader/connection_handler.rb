# frozen_string_literal: true

module ActiveRecordDataLoader
  class ConnectionHandler
    def initialize(connection_factory:, statement_timeout:, output_adapter:)
      @connection_factory = connection_factory
      @statement_timeout = statement_timeout
      @output_adapter = output_adapter
    end

    def with_connection
      connection = open_connection
      if postgres?(connection)
        original_timeout = retrieve_statement_timeout(connection)
        update_statement_timeout(connection, statement_timeout)
        yield connection
        update_statement_timeout(connection, original_timeout)
      else
        yield connection
      end
    ensure
      connection&.close
    end

    # When the output is going to a script file, there are two places to update the
    # statement_timeout. The connection itself needs to have the timeout updated
    # because we are reading data from the connection to come up with related data
    # while generating the data. Also, the final SQL script file needs the timeout
    # updated so that when those \COPY commands are executed they have the higher
    # timeout as well.
    def with_statement_timeout_for_output
      return yield unless output_adapter.needs_timeout_output?

      original_timeout = begin
        connection = open_connection
        retrieve_statement_timeout(connection) if postgres?(connection)
      ensure
        connection&.close
      end

      if original_timeout
        output_adapter.execute(statement_timeout_set_command(statement_timeout))
        yield
        output_adapter.execute(statement_timeout_set_command(original_timeout))
      else
        yield
      end
    end

    private

    attr_reader :connection_factory, :statement_timeout, :output_adapter

    def retrieve_statement_timeout(connection)
      connection.execute("SHOW statement_timeout").first["statement_timeout"]
    end

    def update_statement_timeout(connection, timeout)
      connection.execute(statement_timeout_set_command(timeout))
    end

    def statement_timeout_set_command(timeout)
      "SET statement_timeout = \"#{timeout}\""
    end

    def open_connection
      connection_factory.call
    end

    def postgres?(connection)
      connection.adapter_name.downcase.to_sym == :postgresql
    end
  end
end
