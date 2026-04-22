# frozen_string_literal: true

RSpec.describe MysqlDumpToJson::MySQL::Database do

  before(:all) {
    @db = MysqlDumpToJson::MySQL::Database.new({})
  }

  describe 'creation functionality' do
    it 'creates tables shell' do
      expect(@db.tables).to be_instance_of(Hash)
    end
  end


end
