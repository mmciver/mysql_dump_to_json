# frozen_string_literal: true

module MysqlDumpToJson
  module MySQL

    autoload :Reader, 'mysql_dump_to_json/mysql/reader'

    autoload :Database, 'mysql_dump_to_json/mysql/database'
    autoload :Table, 'mysql_dump_to_json/mysql/table'
    autoload :Row, 'mysql_dump_to_json/mysql/row'

  end
end
