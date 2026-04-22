# frozen_string_literal: true

module MysqlDumpToJson
  module MySQL
    class Table

      attr_reader :name, :fields, :keys, :rows

      def initialize(name, fields, keys)
        @name = name
        @fields = fields
        @keys = keys
        @rows = []
      end

      def add_row(fields, values, prevent_duplicates = false)
        row = fields.zip(values).to_h
        return if prevent_duplicates && @rows.include?(row)

        @rows << row
      end

      def description
        {
          name: name,
          num_rows: rows.length,
          first_row: rows.first
        }
      end
    end

  end

end
