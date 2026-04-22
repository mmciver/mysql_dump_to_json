# frozen_string_literal: true

module MysqlDumpToJson
  module MySQL

    class Database

      attr_reader :opts, :tables

      def initialize(opts = {})
        @opts = opts
        @tables = {}
      end

      def create_table(name, fields, keys)
        @tables[name] = MysqlDumpToJson::MySQL::Table.new(name, fields, keys)
        @tables.fetch(name)
      end

      def to_hash
        tables.map do |table_name, table|
          [table_name, { keys: table.keys, rows: table.rows }]
        end.to_h
      end

      def table_names
        @tables.keys
      end

      def describe_tables
        @tables.map do |table_name, table|
          table.description
        end
      end

      def describe_table(table_name)
        @tables.fetch(table_name).description
      end

    end

  end
end
