# = RedisRecord extensions
#
# This extensions should be required manually and add the following specific funcionality:
#
#  * populate_from_yaml: Allows you to populate a DB from a YAML file.
#  * Sphinx extensions:
#    * sphinx_export: Export records to xmlpipe2-compatible XML files.
#    * search: Sphinx query interface for RedisRecord.
#
require 'yaml'

begin
  require 'xml'
rescue LoadError
  $stderr.puts '[error] Missing gem: "libxml-ruby". Try: sudo gem install libxml-ruby'
end

begin
  require 'riddle'
rescue LoadError
  $stderr.puts '[error] Missing gem: "riddle". Try: sudo gem install riddle'
end

module RedisRecord
  class Base
    class << self
      # IMPORTANT: This method is part of the *RedisRecord extensions*.
      #
      # Accepts a YAML file as input to populate the database. 
      #
      # A sample YAML file can be found in the *samples* directory.
      def populate_from_yaml(yaml_file)
        entries = YAML::load_file(yaml_file)
        records = []
        entries.keys.each do |k|
          begin
            r = new(entries[k])
        	  r.save 
        	  records << r
          rescue Exception => e 
        	  records << nil
          end
        end
        records
      end

      # IMPORTANT: This method is part of the *RedisRecord extensions*.
      #
      # Generates an Sphinx xmlpipe2-compatible XML file ready to be
      # indexed.
      #
      # Parameters:
      #  * records: An array of RedisRecord entries
      #  * outfile: Output XML file path. Default is '/tmp/redisindex.xml'
      #
      # Depends on: *libxml-ruby* gem.
      #
      # A sample *sphinx.conf* file can be found in the *samples* directory.
      def sphinx_export(records, outfile='/tmp/redisindex.xml')
        sphinx_docset = XML::Document.new()
        sphinx_docset.root = XML::Node.new('sphinx:docset')
        
        sphinx_schema = XML::Node.new('sphinx:schema')
        records_attrs = records.map {|r| r.attrs }
        records_attrs.flatten!.uniq!
        [:created_at, :updated_at].each do |a|
          records_attrs.delete(a)
          sphinx_attr = XML::Node.new('sphinx:attr')
          sphinx_attr.attributes['name'] = a.to_s
          sphinx_attr.attributes['type'] = 'timestamp'
          sphinx_schema << sphinx_attr
        end

        records_attrs.each do |a|
          sphinx_field = XML::Node.new('sphinx:field')
          sphinx_field.attributes['name']= a.to_s
          sphinx_schema << sphinx_field
        end
        sphinx_attr = XML::Node.new('sphinx:field')
        sphinx_attr.attributes['name'] = 'class'
        sphinx_schema << sphinx_attr
        
        sphinx_docset.root << sphinx_schema
        
        records.each do |record| 
          sphinx_doc = XML::Node.new('sphinx:document')
          sphinx_doc.attributes['id'] = record.id
          sphinx_doc << XML::Node.new('class', record.class.name)
          record.attrs.each {|key| sphinx_doc << XML::Node.new(key, record.send(key).to_s) }
          sphinx_docset.root << sphinx_doc 
        end
        
        sphinx_docset.save(outfile)
        sphinx_docset
      end

      # IMPORTANT: This method is part of the *RedisRecord extensions*.
      #
      # Sphinx client for RedisRecord. Accepts Sphinx extended[http://www.sphinxsearch.com/docs/current.html#extended-syntax] query syntax.
      #
      # Depends on: *riddle* gem.
      def search(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        client = Riddle::Client.new
        client.match_mode = :extended
        q = client.query("#{args} @class #{name}")
        ids = q[:matches].map {|r| r[:doc]}
        find(ids)
      end
    end
  end
end
