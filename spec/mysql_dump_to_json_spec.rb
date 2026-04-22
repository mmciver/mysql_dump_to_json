# frozen_string_literal: true

RSpec.describe MysqlDumpToJson do
  it "has a version number" do
    expect(MysqlDumpToJson::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(MysqlDumpToJson).to eq(MysqlDumpToJson)
    expect(MysqlDumpToJson::MySQL).to eq(MysqlDumpToJson::MySQL)
    expect(MysqlDumpToJson::MySQL::Reader).to eq(MysqlDumpToJson::MySQL::Reader)
    expect(MysqlDumpToJson::MySQL::Table).to eq(MysqlDumpToJson::MySQL::Table)
    expect(MysqlDumpToJson::MySQL::Row).to eq(MysqlDumpToJson::MySQL::Row)
  end
end
