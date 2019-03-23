require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info('#{table_name}')"
    table_info = DB[:conn].execute(sql)
    result = table_info.each {|element| element["name"]}
    result.compact #Gets rid of nulls
  end

  def initialize(hash = {})
    hash.each {|key, value| self.send("#{key}=", value)}
    #binding.pry
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert #Checks to see if it has id then deletes if true. Joins them into string
    self.class.column_names.delete_if {|element| element == "id"}.join(", ")
  end

  def values_for_insert
    arr = []
    self.class.column_names.each {|element| arr << "'#{send(element)}'" unless send(element).nil?}
    arr.join(", ")
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

  def self.find_by(attribute)
    attribute_key = attribute.keys[0].to_s
    attribute_value = attribute.values[0]
    sql = "SELECT * FROM #{self.table_name} WHERE #{attribute_key} = #{attribute_value}"
    DB[:conn].execute(sql)
  end
end
