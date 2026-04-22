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
          when /^PRIMARY +KEY/i, /^FOREIGN +KEY/i
            table[:keys] << line.strip.delete_suffix(',')
          when ');'
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
          parse_values_row_with_escape(values_row)
        end
      end

      def parse_values_row_with_escape(values_row)
        values = values_row.scan(/('.*?'(?=,)|NULL)/).flatten
        values.map do |value|
          value.delete_suffix("'") # Remove the enacapsulating quotes
               .delete_prefix("'")
               .gsub("\\'", "'") # Remove the double escaped interior single quotes
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
