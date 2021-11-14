# frozen_string_literal: true

module ActiveRecordDataLoader
  class ConnectionHandler
    def initialize(connection_factory:, statement_timeout:)
      @connection_factory = connection_factory
      @statement_timeout = statement_timeout
      cache_facts
    end

    def with_connection
      connection = connection_factory.call
      if supports_timeout?
        connection.execute(timeout_set_command)
        yield connection
        connection.execute(reset_timeout_command)
      else
        yield connection
      end
    ensure
      connection&.close
    end

    def supports_timeout?
      @supports_timeout
    end

    def supports_copy?
      @supports_copy
    end

    def timeout_set_command
      "SET statement_timeout = \"#{statement_timeout}\""
    end

    def reset_timeout_command
      "RESET statement_timeout"
    end

    private

    attr_reader :connection_factory, :statement_timeout

    def cache_facts
      connection = connection_factory.call
      @supports_timeout = connection.adapter_name.downcase.to_sym == :postgresql
      @supports_copy = connection.raw_connection.respond_to?(:copy_data)
    ensure
      connection&.close
    end
  end
end
