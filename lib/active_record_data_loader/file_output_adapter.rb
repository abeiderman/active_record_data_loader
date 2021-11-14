# frozen_string_literal: true

module ActiveRecordDataLoader
  class FileOutputAdapter
    def self.with_output_options(options)
      adapter = new(options)
      pre_command = options[:pre_command]
      adapter.write_command(pre_command) if pre_command
      yield adapter
      post_command = options[:post_command]
      adapter.write_command(post_command) if post_command
    end

    def initialize(options)
      @filename = options.fetch(:filename, "active_record_data_loader_script.sql")
      @file_basename = File.basename(@filename, File.extname(@filename))
      @path = File.expand_path(File.dirname(@filename))
      File.open(@filename, File::TRUNC) if File.exist?(@filename)
    end

    def copy(connection:, table:, columns:, data:, row_numbers:)
      data_filename = data_filename(table, row_numbers)
      File.open(data_filename, "w") { |f| f.puts(data) }
      File.open(filename, "a") do |file|
        file.puts("\\COPY #{table} (#{columns}) FROM '#{data_filename}' WITH (FORMAT CSV);")
      end
    end

    def insert(connection:, command:)
      write_command(command)
    end

    def write_command(command)
      File.open(filename, "a") { |f| f.puts("#{command.gsub("\n", ' ')};") }
    end

    private

    attr_reader :filename, :path, :file_basename

    def data_filename(table, row_numbers)
      File.join(
        path,
        "#{file_basename}_#{table.gsub(/"/, '')}_rows_#{row_numbers[0]}_to_#{row_numbers[-1]}.csv"
      )
    end
  end
end
