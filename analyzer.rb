$LOAD_PATH << File.join(".",'/R-validation/acrometrix')


require 'bundler/setup'

require "mongo_mapper"
require "csv"
require "gibberish"
require 'bicrypt'
require "chronic"
require "colored"






### Specify Database name; dynamic based on dir
DATABASE_NAME=File.basename File.absolute_path "."



MongoMapper.database = DATABASE_NAME




### Encryption and decryption
# monkeypatching String
class String
  ### cypher p p
  def self.set_encryption
    cypher=prompt "enter encryption cypher: "
    $e = BiCrypt.new(cypher)
  end
  def decrypt
    if $e==nil then String.set_encryption end
    $e.decrypt_string Base64.decode64 self.encode('ascii-8bit')
  end
  def encrypt
  if $e==nil then String.set_encryption end
  Base64.encode64($e.encrypt_string(self)).encode('utf-8')
  end
  # some normalization of SS entries necessary
  def md5
  Gibberish::MD5 (self.gsub "-","").strip()
  end
end

### creates a mongomapper class
def make_mongo_class class_name
  self.instance_variable_set "@#{class_name}", Class.new
  c=self.instance_variable_get "@#{class_name}"
  c.class_eval do
    include MongoMapper::Document
  end
  c
end

###Utility for extrapolating MongoType
# need dates...
class String
  def correct
    case self
    when "String"
      "String"
    when "Fixnum"
      "Integer"
    end
  end
end

##Array of rows to excel file
class Array
  def to_table
    t=Tempfile.new("foo")
    self.each do |row|
      t.write row.to_csv
    end
    t.close
    puts t.path
    new_table=CSV.table t.path
    `rm #{t.path}`
    new_table
  end
end




class CSV::Row
  def pp
    self.to_hash
  end

end




### A modified CSV table class
# Can Decrypt and encrypt
class CSV::Table
  attr_accessor :file_path, :data_classifier

  def encrypt col_name
    if $e==nil then String.set_encryption end
    self.each do |row|
      row[col_name]=row[col_name].to_s.encrypt
    end
  end

  def encrypt_col_names col_names_array
    col_names_array.each do |col_name|
      self.encrypt col_name
    end
  end

  def decrypt col_name
    if $e==nil then String.set_encryption end
    self.each do |row|
      row[col_name]=row[col_name].to_s.decrypt
    end
  end

  def clean_names names_col, diagnosis_col
    self.each do |row|
      row[diagnosis_col]=names_cleaner row[diagnosis_col],row[names_col]
    end
  end

  def md5 col_name
    self.each do |row|
      row[col_name]=row[col_name].to_s.md5
    end
  end

  def save file_name
    CSV.open(file_name, "wb") do |csv|
      csv << self.headers
      self.each do |line|
        csv << line.fields
      end
    end
  end

  #z.find_rows :diagnosis_text,  /.(T\d)./i
  def find_rows col_name, regex, decrypt=false
    new_table=[]<<self.headers
    if decrypt then self.decrypt col_name end
    self[col_name].each_with_index do |r,i|
      #puts r
      if r.match regex
        puts i
        new_table<<self[i]
      end
    end
    new_table.to_table
  end

  def to_mongo mongo_class
    self.each_with_index do |row,i|
      m=mongo_class.new
      self.headers.each do |header|
        puts "working on #{header} in row #{i}"
        m[header]=row[header]
      end
      m.save
      puts "#{i}: #{mongo_class.count}"
    end
  end

  def mongo_code
    self.data_classifier.print_class
  end
  alias :print_mongo :mongo_code
end

###Check if a file is an idiotic ; csv
# by counting ; and , in header line
def is_semicolon? file_path
  csv=CSV.read(file_path)
  if (csv and csv.count !=0)
    puts file_path
    header=csv[0][0]
    if header==nil then return false end
    if (header and header.count(";"))>header.count(",")
      return true
    else
      return false
    end
  end
end

###Check if a tab file
# by counting \t and , in header line
def is_tab? file_path
  csv=CSV.read(file_path)
  if (csv and csv.count !=0)
    puts file_path
    header=csv[0][0]
    if header==nil then return false end
    if (header and header.count("\t"))>header.count(",")
      return true
    else
      return false
    end
  end
end


### Remove semicolons
# ; => ,
def remove_semicolon file_path
  puts "removing semicolons in #{file_path}"
  c=CSV.table file_path, :col_sep=> ";"
  fh=File.new file_path, "w"
  fh.write c.to_csv
  fh.close
  return file_path
end

### Remove tabs
# ; => ,
def remove_tabs file_path
  puts "removing tabs in #{file_path}"
  c=CSV.table file_path, :col_sep=> "\t"
  fh=File.new file_path, "w"
  fh.write c.to_csv
  fh.close
  ext=File.extname file_path
  if (ext==".xls" or ext==".txt")
    new_file_name= (file_path.gsub ext, ".csv").gsub(" ","_")
    FileUtils.cp file_path,new_file_name
    return new_file_name
  else
    return file_path
  end
end

def remove_header_dots file_path
  lines=File.readlines file_path
  lines[0]=lines[0].gsub("\.","_")
  puts lines[0]
  lines[0]=lines[0].split(",").map{|x|x.gsub(/^\d/,"n")}.join(",")
  File.write file_path, lines.join
  file_path
end


def remove_header_spaces file_path
  lines=File.readlines file_path
  lines[0]=lines[0].gsub(" ","_")
  puts lines[0]
  lines[0]=lines[0].split(",").map{|x|x.gsub(/^\d/,"n")}.join(",")
  File.write file_path, lines.join
  file_path
end


### A modified CSV table class
# Can Decrypt and encrypt
class CSV::Table
  attr_accessor :file_path, :data_classifier

  #remove duplicates
  #
  #takes col to search through
  def remove_duplicate  col
    col_all=self[col]
    self.each do |row|
      entry=row[col]
      if col_all.count(entry) >= 2
        # deletes entries from index and from table
        self.delete col_all.rindex(entry)
        col_all.delete_at col_all.rindex(entry)
      end
    end
  end
end



def make_class_name file_path
  File.basename((file_path).gsub(".","_").gsub("@","").gsub("%","").gsub("-","")).camelize

end


module StringToMongo

  def self.nil? text_string
    if text_string==nil
      true
    else
      false
    end
  end
  def self.integer? text_string
    if text_string.match /^\d*$/
      true
    else
      false
    end
  end

  def self.float? text_string
    if text_string.match /^\d*\.\d*$/
      true
    else
      false
    end
  end

  def self.date? text_string
    begin
      if Chronic.parse(text_string) != nil
        true
      else
        false
      end
    rescue
      false
    end
  end

  def self.mongo_type text_string
    case
    when nil?(text_string)
      "String"
    when integer?(text_string)
      "Integer"
    when float?(text_string)
      "Float"
    when date?(text_string)
      "Time"
    else
      "String"

    end
  end
end

module ColName
  def self.fix_spaces col_name
    col_name.gsub(".","_").gsub(" ","_")
  end

  def self.fix_numbers col_name
    matches=(col_name.scan /(\d)/)
    if matches==[]
      puts "no match"
      return col_name
    else
      n=matches[0]
      puts "captures #{n} #{n.class}"
      case n
      when "1"
        puts n
        col_name.gsub!(n,"one")
      when "2"
        puts n
        col_name.gsub!(n,"two")
      when "3"
        puts n
        col_name.gsub!(n,"three")
      when "4"
        puts n
        col_name.gsub!(n,"four")
      when "5"
        puts n
        col_name.gsub!(n,"five")
      when "6"
        puts n
        col_name.gsub!(n,"six")
      when "7"
        puts n
        col_name.gsub!(n,"seven")
      when "8"
        puts n
        col_name.gsub!(n,"eight")
      when "9"
        puts n
        col_name.gsub!(n,"nine")
      end
    end
    col_name
  end
end

###Creates a Mongo Class mapping csv file
#
#d=DataClassifier.new "/Users/carlobifulco/Dropbox/code/next_gen/hotspot2.csv"
#d.print_class
class DataClassifier
  attr_accessor :headers, :fs_line,:keys_types,:file_name,:template
  def initialize file_name="test.csv"

    @header_zip=self.cheap_headers file_name

    @file_name=file_name
    @class_name=make_class_name file_name
    #self.instance_variable_set "@#{@class_name}",make_mongo_class(@class_name)

    @template="""
class #{@class_name}
  include MongoMapper::Document
  include DataUtilities
  safe
  timestamps!
    """
  end



  def cheap_headers file_path
    index=0
    container=[]
    CSV.foreach(file_path) do |row|
      container<<row
      #puts row
      index+=1
      if index>2 then break end
    end
    container[0]=container[0].map{|x| x.gsub(".","_").downcase}
    zipped=container[0].zip container[1]
    zipped.select {|x| x[0]!="" and x[0]!=nil}
  end


  def mongo_types
    @header_zip.each_with_object({})  do |hz,container|
      key=hz[0].gsub(" ","_")
      container[hz[0].to_sym]=StringToMongo.mongo_type hz[1]
    end
  end

  #prints the class
  def print_class
    puts template
    self.mongo_types.sort_by{|k,v| k}.each do |r|
      puts "  key :#{r[0]}, #{r[1]} "
    end
    puts "end"
  end

end




### Convenience for Mongomapper classes
#
# export to csv
#
# pretty printing of keys
module DataUtilities

  ### Export csv
  #
  # file_path - the file to be exported to
  # XXX currently not working
  def self.export file_path
    CSV.open(file_path, "wb") do |csv|
      headers=self.class.keys.keys.sort
      puts headers
      csv << headers
      self.class.all.each do |c|
        line=[]
        headers.each do |h|
          line<<(c[h]).to_s
        end
        csv << line
      end
      puts csv
    end
  end


  def pp
    self.keys.keys.sort.each do |k|
      if self[k].class==BSON::Binary
        puts "#{k.yellow}: binary blob"
      else
        puts "#{k.yellow}: #{self[k].to_s.red}"
      end
    end
    nil
  end

  def pp_to_s
    text=[]
    self.keys.keys.sort.each do |k|
      text<< " #{k}: #{self[k]};"
    end
    text.join ""
  end

  def pp_to_html
    text=[]
    self.keys.keys.sort.each do |k|
      text<< " #{k}: #{self[k]};"
    end
    text=text.join ""
    text.gsub ";", "<br>"
  end

end


### Utility function to create mongomapper keys
#
# takes a file_path of teh csv file
#
# prints keys in mongomapper format
def csv_headers_to_keys file_path
  CSV.table(file_path).headers.sort!.each do |x|
      puts "key :#{x}, String"
  end
end



###Utility for exporting a mongomapper search or an array\
#   of MongoMapper instances
#
# takes a file name where all will be saved to in a csv format
#
#saves csv file
class Array
  def mongo_to_csv file_path
    CSV.open(file_path, "wb") do |csv|
      headers=self[0].class.keys.keys.sort
      puts headers
      csv << headers
      self.each do |c|
        line=[]
        headers.each do |h|
          line<<(c[h]).to_s
        end
        csv << line
      end
      puts csv
    end
  end

  def mongo_to_table
    file_path=Tempfile.new "test"
    self.mongo_to_csv file_path
    r=CSV.table file_path
    `rm #{file_path}`
    r
  end

end




### A modified CSV table class
# pp
class CSV::Table
  def pp
    puts self.headers.to_csv
    self.each do |r|
      puts r.to_csv
    end
  end
end



def prompt(*args)
    print(*args)
    gets.strip
end


def val_to_csv val_name, file_name
  Case.find_all_by_validation_name(val_name).mongo_to_csv(file_name)
  puts "saved #{Case.find_all_by_validation_name(val_name)} in #{File.absolute_path file_name}"
end

### remove empty columns from CSV files
# also deals with some windows encoding issues if needed
def remove_nil_headers file_path
  return unless  File.exists? file_path
  begin
    c=CSV.read(file_path,:headers => true)
  rescue
    begin
      puts "on windows utf"
      c=CSV.read(@file_name,:headers => true,  :encoding => 'windows-1251:utf-8')
    rescue Exception => e
      puts "FAILURE ON #{file_path}"
      require_relative "mongo_failure"
      f=FailureLog::Failure.new
      f.failure_message=file_path+"#{e.message} #{e.backtrace.inspect}"
      f.save
      return
    end
  end
  if c.headers.include? nil
    c.by_col!
    while c.headers.index(nil) != nil
      c.delete(c.headers.index(nil))
    end
    fh=File.new file_path, "w"
    fh.write c.to_csv
    fh.close
  end
end


### Factory for new tables
# takes care of definiens and also stores file paths
# also removes nil headers\
#also deals with tab formatted files
#
def load_table file_path
  return unless  File.exists? file_path
  if is_semicolon?(file_path)
    file_path=remove_semicolon(file_path)
  elsif is_tab?(file_path)
    file_path=remove_tabs(file_path)
  end
  remove_nil_headers file_path
  remove_header_dots file_path
  c=CSV.table file_path
  c.file_path=file_path
  begin
    c.data_classifier=DataClassifier.new file_path
  rescue
    c.data_classifier=false
  end
  c
end

### MongoLoader
# takes a class and a file csv file and then load it into Mongo
# def mongo_loader mongo_class, file_path
#   counter=0
#   CSV.foreach(file_path) do |row|
#     #puts row
#     puts counter
#     if counter==0
#       @headers=row
#       counter+=1
#       next
#     end
#     puts counter
#     m=mongo_class.new
#     row.each_with_index do |e,i|

#       #puts "HEADERS: #{@headers}"
#       #puts @headers[i]
#       m[@headers[i].gsub(".","_").downcase]=e
#       m.save


#     end
#     puts counter
#     counter+=1
#   end
#   ""
# end



### Load CSV file into mongo class
# Mongo class needs to exist
def csv_to_mongo file_name="test.csv",mongo_class=TestCsv
  t=CSV.table file_name
  t.each_with_index do |row,i|
    m=mongo_class.new
    t.headers.each do |header|
      m[header]=row[header]
    end
    m.save
    puts "#{i}: #{mongo_class.count}"
  end
end


### Splits name in array components
# always returns array
def name_split text_string
  if text_string.index " " or  text_string.index ","
    return (text_string.split(" ").split(",") ).flatten
  else
    return [text_string].flatten
  end

end


### Removes names from surg path text
#
def names_cleaner text, names

  names.map!{|z| split_if_space z}.flatten! if names.class==Array
  names=name_split names if names.class==String
  names.each do |n|

    r=Regexp.new(n, Regexp::IGNORECASE)
    text.gsub! r,""
    puts "cleaned #{n}"
  end
  text
end



### Dictionary of arrays; for data summary
class Hash
  def export_to_csv csv_file_path
    self.equalize
    CSV.open(csv_file_path, "wb") do |csv|
      csv << self.keys
      greatest_array_count.times do |i|
        line=[]
        self.keys.each do |k|
          line<<self[k][i]
        end
        csv<<line
      end
    end
  end

  def greatest_array_count
    self.values.map{|x| x.count}.max
  end
# d={:a=>[1,2,3],:b=>[1,2,3,4,5,6]}
# d.equalize
# d => {:a=>[1, 2, 3, "NA", "NA", "NA"], :b=>[1, 2, 3, 4, 5, 6]}
  def equalize
    self.keys.each do |k|
       n=greatest_array_count-self[k].count
       self[k]=(self[k].append(NA_times n)).flatten
    end
  end


  def NA_times n_times
    a=[]
    n_times.times.each do |i|
      a<<"NA"
    end
    a
  end

end
