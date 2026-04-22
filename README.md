# MySQLDumpToJSON

Convert a mysql dump file to json directly, no mysql dependencies needed

## Install

```shell
$ gem install mysql_dump_to_json
```

Or with bundler:

```ruby
gem 'mysql_dump_to_json'
```

## Usage

Load a dump from into a string, then use like so:

```ruby
MysqlDumpToJson.string_to_json(dump_string)
```

The dump file is read and an internal database object is created, which is then converted to a hash object and cast to JSON.

Alternate serialization is possible by returning the hash object without casting to JSON:

```ruby
MysqlDumpToJson.dump_to_hash(dump_string)
```

More fine grained control is possible by accessing the database object created directly:
```ruby
db = MysqlDumpToJson.database_object(dump_string)
```

The database can be examined in a few ways:
```ruby
db = MysqlDumpToJson.database_object(dump_string)
db.table_names # Array of table names
db.describe_table(table_name) # Hash of some basic meta data about the table
db.describe_tables # Hash of all table descriptions
```

## Contributing / Support

If you experience any issue, have a question or a suggestion, or if you wish
to contribute, feel free to open an issue
