# frozen_string_literal: true

require 'pry'

module MysqlDumpToJson
  module MySQL

    class Reader

      attr_reader :database, :opts, :source_dump, :statements

      def initialize(database, opts = {})
        @database = database
        @tables = {}
        @opts = opts
      end

      def ingest(mysql_string)
        @source_dump = mysql_string
        @statements = compress_sql_into_statements
        build_database
      end

      # Creating the database as objects

      def build_database
        @statements.each_with_index do |sql_statement|
          case sql_statement
          when /^CREATE +DATABASE/i,
              /^USE/i,
              /^DROP +TABLE/i,
              /^LOCK TABLES/i,
              /^UNLOCK TABLES/i, ';'
            next
          when /^CREATE +TABLE/i
            create_table(sql_statement)
          when /^INSERT +INTO/i
            insert_into(sql_statement)
          else
            warn " !!! SQL statement found that is not handled by this gem: #{sql_statement.split("\n").first}"
          end
        end
        @database
      end

      def create_table(sql_statement)
        table = create_table_definition(sql_statement)
        @database.create_table(table[:name], table[:fields], table[:keys])
      end

      def create_table_definition(sql_statement)
        table = { name: nil, fields: [], keys: [] }
        sql_statement.split("\n").each do |line|
          case line.strip
          when /^CREATE +TABLE +/i
            table[:name] = table_name_from_create(line)
          when /^PRIMARY +KEY/i, /^FOREIGN +KEY/i, /^KEY/i
            table[:keys] << line.strip.delete_suffix(',')
          when ');', /ENGINE=/i, /^CONSTRAINT/i, /^ENGINE/i
          else
            table[:fields] << field_from_line(line)
          end
        end
        table
      end

      def table_name_from_create(str)
        str.strip.gsub(/CREATE +TABLE +`?/i,'').delete_suffix("(").strip.delete_suffix('`')
      end

      def field_from_line(line)
        line.strip.scan(/[a-z0-9_$]+/i).first
      end

      def insert_into(sql_statement)
        table_name = table_name_from_insert(sql_statement)
        table = @database.tables.fetch(table_name)
        insert_fields = fields_from_insert(sql_statement) || table.fields
        value_chunks_from_insert(sql_statement).each do |row_ary|
          table.add_row(insert_fields, row_ary)
        end
      end

      def table_name_from_insert(sql_statement)
        sql_statement.split(/[ ()`]+/)[2]
      end

      def fields_from_insert(sql_statement)
        before_values_section = sql_statement.split(/values/i).first
        field_section = before_values_section.gsub(/^INSERT INTO ['`]?#{table_name_from_insert(sql_statement)}['`]?/i,'').strip
        return false if field_section.empty? || field_section.nil?

        sql_statement.split(/[()]/)[1].split(',')
      end

      def value_chunks_from_insert(sql_statement)
        values_str = sql_statement.split(/ VALUES +/i).last
        values_ary = values_str[1..-3].split(/\)\s*,\s*\(/)
        values_ary.map do |values_row|
          parse_values_row_with_escape(values_row.delete_prefix('(').delete_suffix(')'))
        end
      end

      # Simply splitting on commas gets most rows, but fails when there are commas in quoted text.
      # When an opening quote is found, but not a closing quote, look ahead in the array until the
      # closing quote is found to merge those values back together with the consumed comma
      def parse_values_row_with_escape(values_row)
        simple_split = values_row.split(',')
        values = []
        merged_indexes = []
        simple_split.each_with_index do |value, index|
          next if merged_indexes.include?(index)

          if value_not_quoted?(value)
            values << value_to_numeric(value)
          elsif value_complete_quote?(value)
            values << value
          elsif value_open_end_quote?(value)
            end_of_quote_index = index_of_closing_quote_value(simple_split, index)
            values << simple_split[index..end_of_quote_index].join(',')
            merged_indexes |= (index..end_of_quote_index).to_a
          else
            binding.pry
          end
        end
        remove_quotes_from_values(values)
      end

      def remove_quotes_from_values(values)
        values.map do |value|
          if value.is_a?(String)
            value.delete_suffix("'") # Remove the enacapsulating quotes
                 .delete_prefix("'")
                 .gsub("\\'", "'") # Remove the double escaped interior single quotes
          else
            value
          end
        end
      end

      def value_to_numeric(value)
        return nil if value == 'NULL'
        return value.to_i if value.to_i.to_s == value
        return value.to_f if value.to_f.to_s == value

        binding.pry
      end

      def value_not_quoted?(value)
        value.count("'").zero?
      end

      def value_complete_quote?(value)
        value[0] == "'" &&
            value[-1] == "'"
      end

      def value_open_end_quote?(value)
        value[0] == "'" &&
            value[-1] != "'"
      end

      def value_open_start_quote?(value)
        value[0] != "'" &&
            value[-1] == "'"
      end

      def index_of_closing_quote_value(ary, start_at_index)
        ary.each_with_index do |value, index|
          next if index < start_at_index
          return index if value_open_start_quote?(value)
        end
      end




      # Compressing the source into distinct SQL statements

      def compress_sql_into_statements
        str = remove_block_comments(@source_dump)
        uncommented = strip_comments(str)
        uncommented.split(/(?<=;)[\r\n]/)
      end

      def strip_comments(str)
        str.split(/[\n\r]+/).reject do |line|
          line.nil? ||
              line.empty? ||
              line.start_with?('--')
        end.join("\n")
      end

      def remove_block_comments(str)
        str.gsub(/\/\*.*?\*\//m,'')
      end

    end

  end

end
