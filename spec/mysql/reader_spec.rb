# frozen_string_literal: true

RSpec.describe MysqlDumpToJson::MySQL::Reader do

  before(:all) {
    @db = MysqlDumpToJson::MySQL::Database.new({})
    @reader = MysqlDumpToJson::MySQL::Reader.new(@db, {})
    @mysql_test_file = IO.read('spec/fixtures/mysqlsampledatabase.sql')
    @reader.ingest(@mysql_test_file)
    @products_statement = @reader.statements[10]
    @offices_statement = @reader.statements[19]
    @custom_test_database = (ENV['CUSTOM_TEST_FILE'] ? MysqlDumpToJson.database_object(IO.read(ENV['CUSTOM_TEST_FILE'])) : nil)

  }

  describe 'creation functionality' do
    it 'sees the database' do
      expect(@reader.database).to eq(@db)
    end
  end

  describe 'reading' do
    describe 'string manipulation' do
      describe 'table_name_from_create' do
        it 'extracts the table name' do
          expect(@reader.table_name_from_create("CREATE TABLE products (")).to eq('products')
          expect(@reader.table_name_from_create("CREATE TABLE products(")).to eq('products')
          expect(@reader.table_name_from_create("CREATE  TABLE products (")).to eq('products')
        end
      end
      describe '.field_from_line' do
        it 'extracts the field name' do
          expect(@reader.field_from_line('  productVendor varchar(50) NOT NULL,')).to eq('productVendor')
        end
      end

      describe 'table_name_from_insert' do
        it 'extracts the table name' do
          expect(@reader.table_name_from_insert(@offices_statement)).to eq('offices')
        end
      end

      describe 'fields_from_insert' do
        it 'extracts the field names' do
          expect(@reader.fields_from_insert(@offices_statement)).to eq(["officeCode", "city", "phone", "addressLine1", "addressLine2", "state", "country", "postalCode", "territory"])
        end
      end

      describe 'value_chunks_from_insert(sql_statement)' do
        it 'extracts values from the insert statement' do
          expect(@reader.value_chunks_from_insert(@offices_statement)).to be_instance_of(Array)
          expect(@reader.value_chunks_from_insert(@offices_statement).length).to eq(7)
          expect(@reader.value_chunks_from_insert(@offices_statement).first).to be_instance_of(Array)
          expect(@reader.value_chunks_from_insert(@offices_statement).first.length).to eq(9)
          expect(@reader.value_chunks_from_insert(@offices_statement).first).to eq([1, "San Francisco", "+1 650 219 4782", "100 Market Street", "Suite 300", "CA", "USA", "94080", 'NA'])
          expect(@reader.value_chunks_from_insert(@offices_statement)[3]).to eq([4, "Paris", "+33 14 723 4404", "43 Rue Jouffroy D'abbans", nil, nil, "France", "75017", 'EMEA'])
        end
      end
    end

    describe 'mysql ingestion' do
      it 'compresses the lines into distinct sql statements' do
        expect(@reader.statements.length).to eq(25)
        expect(@reader.statements.first).to eq('CREATE DATABASE  IF NOT EXISTS classicmodels;')
        expect(@reader.statements[5]).to eq('DROP TABLE IF EXISTS employees;')
      end

      it 'builds the database' do
        expect(@reader.build_database).to eq(@db)
      end

      it 'correctly defines the tables' do
        expect(@products_statement).to be_instance_of(String)
        expect(@products_statement.split("\n").length).to eq(13)
        expect(@reader.create_table_definition(@products_statement)).to be_instance_of(Hash)
        expect(@reader.create_table_definition(@products_statement)[:name]).to eq('products')
        expect(@reader.create_table_definition(@products_statement)[:keys]).to eq(['PRIMARY KEY (productCode)','FOREIGN KEY (productLine) REFERENCES productlines (productLine)'])
        expect(@reader.create_table_definition(@products_statement)[:fields]).to eq(['productCode','productName','productLine','productScale','productVendor','productDescription','quantityInStock','buyPrice','MSRP'])
      end

      it 'creates the correct tables' do
        expect(@reader.database.tables.keys).to eq(['productlines','products','offices','employees','customers','payments','orders','orderdetails'])
        expect(@reader.database.tables.fetch('products')).to be_instance_of(MysqlDumpToJson::MySQL::Table)
      end

      it 'preserves the mysql key assignments' do
        expect(@reader.database.tables.fetch('products').keys).to eq(['PRIMARY KEY (productCode)','FOREIGN KEY (productLine) REFERENCES productlines (productLine)'])
      end

      it 'loads the data to the correct tables' do
        #expect(@reader.statements[19].split("\n")).to eq([])
        expect(@reader.database.tables.fetch('offices').rows.length).to eq(7)
        expect(@reader.database.tables.fetch('offices').rows.first.keys).to eq(["officeCode", "city", "phone", "addressLine1", "addressLine2", "state", "country", "postalCode", "territory"])
        expect(@reader.database.tables.fetch('offices').rows.first.values).to eq([1, "San Francisco", "+1 650 219 4782", "100 Market Street", "Suite 300", "CA", "USA", "94080", 'NA'])
      end

      describe 'loading a custom test file' do
        before do
          skip "No custom test file passed via environment variable CUSTOM_TEST_FILE" unless ENV['CUSTOM_TEST_FILE']
        end

        it 'loads a custom test file' do
          expect(@custom_test_database).to be_instance_of(MysqlDumpToJson::MySQL::Database)
        end

        it 'has tables defined' do
          expect(@custom_test_database.table_names.empty?).to be(false)
          puts JSON.pretty_generate(@custom_test_database.describe_tables)
        end
      end
    end

  end


end
