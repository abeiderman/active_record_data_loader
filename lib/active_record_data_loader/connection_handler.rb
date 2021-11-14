# frozen_string_literal: true

module ActiveRecordDataLoader
  class ConnectionHandler
    def initialize(connection_factory:, statement_timeout:)
      @connection_factory = connection_factory
      @statement_timeout = statement_timeout
    end

    def with_connection
      connection = open_connection
      if postgres?(connection)
        update_timeout(connection, statement_timeout)
        yield connection
        reset_timeout(connection)
      else
        yield connection
      end
    ensure
      connection&.close
    end

    def supports_timeout?
      return @supports_timeout if defined?(@supports_timeout)

      @supports_timeout = begin
        connection = open_connection
        postgres?(connection)
      ensure
        connection&.close
      end
    end

    def timeout_set_command(timeout)
      "SET statement_timeout = \"#{timeout}\""
    end

    def reset_timeout_command
      "RESET statement_timeout"
    end

    private

    attr_reader :connection_factory, :statement_timeout

    def update_timeout(connection, timeout)
      connection.execute(timeout_set_command(timeout))
    end

    def reset_timeout(connection)
      connection.execute(reset_timeout_command)
    end

    def open_connection
      connection_factory.call
    end

    def postgres?(connection)
      connection.adapter_name.downcase.to_sym == :postgresql
    end
  end
end
