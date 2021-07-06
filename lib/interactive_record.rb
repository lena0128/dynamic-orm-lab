require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
    attr_reader :id
  
    def initialize(option={})
      option.each {|k, v| self.send("#{k}=", v) }
    end
  
    def self.table_name
      self.to_s.downcase.pluralize
    end
  
    def self.column_names
      sql = "PRAGMA table_info('#{self.table_name}')"
  
      table_info = DB[:conn].execute(sql)
      column_names = []
      table_info.each {|col| column_names << col["name"]}
      column_names
    end
  
    def table_name_for_insert
      self.class.table_name
    end
  
    def col_names_for_insert
      self.class.column_names.delete_if{|name| name == "id"}.join(", ")
    end
  
    def self.inherited(childclass)
      childclass.column_names.each {|col| attr_accessor col.to_sym}
  
    end
  
    def save
  
      sql = <<-SQL
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})
      SQL
  
      DB[:conn].execute(sql)
  
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end
  
    def values_for_insert
      x = []
      self.class.column_names.each {|name| x << "'#{send(name)}'" unless send(name).nil?}
  
      x.join(", ")
  
    end
  
    def self.find_by_name(name)
      sql = <<-SQL
      SELECT * FROM #{table_name} WHERE name = ?
      SQL
  
      DB[:conn].execute(sql, name)
  
    end
  
    def self.find_by(hsh)
      key = hsh.keys[0]
      value = hsh.values[0]
      formatted_val = value.class == Fixnum ? value : "'#{value}'"
      sql = <<-SQL
      SELECT * FROM #{table_name} WHERE #{key} = #{formatted_val}
      SQL
  
      DB[:conn].execute(sql)
    end
  
  end