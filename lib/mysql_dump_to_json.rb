# frozen_string_literal: true

require 'json'

require_relative "mysql_dump_to_json/version"

module MysqlDumpToJson

  autoload :MySQL, 'mysql_dump_to_json/mysql/mysql'

  def self.database_object(dump_string, opts = {})
    db = MysqlDumpToJson::MySQL::Database.new(opts)
    reader = MysqlDumpToJson::MySQL::Reader.new(db, opts)
    reader.ingest(dump_string)
    db
  end

  def self.dump_to_hash(dump_string, opts = {})
    db = database_object(dump_string, opts)
    db.to_hash
  end

  def self.string_to_json(dump_string, opts = {})
    if opts.key?(:pretty_generate)
      JSON.pretty_generate(dump_to_hash(dump_string, opts))
    else
      dump_to_hash(dump_string, opts).to_json
    end
  end

end
