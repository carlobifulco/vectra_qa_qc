require_relative "analyzer"
require_relative "mongo_pe_collections"
require "YAML"


CONFIG=YAML.load_file "./config.yaml"

WORKING_DIR=CONFIG["WORKING_DIR"]

CELL_SEG_DATA_REG=CONFIG["CELL_SEG_DATA_REG"]
CELL_SEG_DATA_SUMMARY_REG=CONFIG["CELL_SEG_DATA_SUMMARY_REG"]
IMAGE_SCORE_MAP=CONFIG["IMAGE_SCORE_MAP"]
COMPOSITE_IMAGE=CONFIG["COMPOSITE_IMAGE"]
IMAGE_WITH_PHENOTYPE=CONFIG["IMAGE_WITH_PHENOTYPE"]
IMAGE_WITH_TISSUE_SEG=CONFIG["IMAGE_WITH_TISSUE_SEG"]
TISSUE_SEG_DATA_SUMMARY=CONFIG["TISSUE_SEG_DATA_SUMMARY"]

all="*.*"


def unique_image_id file_name
  /.*\]/.match(File.basename file_name).to_s
end

def image_type file_name
  r=/.*(phenotype_map|composite_image|tissue_seg_map|image_with_tissue_seg|image_with_score_map|image_with_cell_seg_map|image_with_all_seg)\.tif/
  m=r.match file_name
  if m
    #puts m[1].to_s
  else
    return "raw_tif"
  end
  return m[1].to_s if m
end



# takes an image
# returns table path
def image_table_path file_name
  File.dirname(file_name)+"/"+unique_image_id(file_name)+"_cell_seg_data.csv"
end

### takes a glob re and applies action/method symbol on each matching file
# usage example
# match "*.*", :remove_filename_spaces
# match "*cell_seg_data.txt", :clean_pe_tab
# match CELL_SEG_DATA_REG, :fake_action
def match glob, action
  tot=Dir.glob("#{WORKING_DIR}/#{glob}").count
  Dir.glob("#{WORKING_DIR}/#{glob}").each_with_index do |x,i|
    puts "Run #{i}; still missing #{tot-i}".red
    (method action).call(x)
  end
  tot
end


def fake_action x=nil
  puts x
end


##### files preparation

### remove spaces from file names
def remove_filename_spaces file_name
  new_file_name= (file_name.gsub(" ","_"))
  FileUtils.mv file_name,new_file_name if (file_name != new_file_name)
end


### prepare directory by removing all spaces from filenames
def dir_space_in_file_name_cleaner
  Dir.glob("#{WORKING_DIR}/*.*").each{|x|remove_filename_spaces x}
end


### formats headers so that they become compateble with mongo
def clean_pe_tab file_name
  if is_tab?(file_name)
    new_file_name=(remove_tabs file_name )
    puts "csv=#{new_file_name} "
    remove_header_spaces new_file_name
  else
    puts "not a tab #{file_name}"
  end
end

### run before batch load
# removes spaces from file names
# and makes the table headers consistent with the database
def prepare_pe_tables results_matches=[CELL_SEG_DATA_REG,
                                        CELL_SEG_DATA_SUMMARY_REG]
  results_matches.each{|x| match(x,:remove_filename_spaces)}
  results_matches.each{|x| match(x, :clean_pe_tab)}
end





##### Cell seg

### loads a hi-res cell seg data file into mongo
# each row becomes an instance of CellSeq
def cell_seg_data_load file_path
  t=load_table(file_path)
  t.each_with_index do |row,i|
    m=CellSeg.new
    t.headers.each do |header|
      #puts "working on #{header} in row #{i}"
      m[header]=row[header]
    end
    m.save
    c=CaseData.get_case m.case_id
    c.cell_seg << m
    c.save
  end
end

### batch load of tables
def cell_seg_data_batch_load
  match CELL_SEG_DATA_REG.gsub(".txt", ".csv"), :cell_seg_data_load
end


##### Tissue seg



### loads a hi-res cell seg data file into mongo
# each row becomes an instance of CellSeq
def tissue_seg_data_load file_path
  t=load_table(file_path)
  t.each_with_index do |row,i|
    m=TissueSeg.new
    t.headers.each do |header|
      puts "working on #{header} in row #{i}"
      m[header]=row[header]
    end
    m.save
    c=CaseData.get_case m.case_id
    c.tissue_seg << m
    c.save
  end
end

### batch load of tables
def tissue_seg_data_batch_load
  match TISSUE_SEG_DATA_SUMMARY, :tissue_seg_data_load
end






#batch load of images
def image_load_batch

  Dir.glob("#{WORKING_DIR}/*.tif").each{|x| image_load x}
end

#load a image
# link to Case data instance
def image_load file_path
  file_path=File.absolute_path(file_path)
  return false if image_type(file_path)==nil
  #puts "file =#{file_path}"
  h=HpfImage.get_hpf_image file_path
  #puts "here we fail --I hope"
  q=image_type(file_path)
  h.cell_seg_data_summary_table_path=image_table_path(file_path).gsub(" ","_")
  # puts "failure cause is #{q}"
  begin
    #h[image_type(file_path)]=file_path
    h[image_type(file_path)]=file_path
    h.save
    c=CaseData.get_case h.case_id
    c.hpf_image<<h
    c.save
    h
  rescue
    puts "#{'*'*10} ALERT".yellow
    puts "#{q}=>#{file_path}".red
  end
  #
end


###### execute all

def upload_data
  prepare_pe_tables
  cell_seg_data_batch_load
  tissue_seg_data_batch_load
  image_load_batch
end

def delete_all
  CellSeg.delete_all
  HpfImage.delete_all
  TissueSeg.delete_all
  CaseData.delete_all

end


# .*[phenotype_map|composite_image|score_map|tissue_seq_map|cell_seg_map]\.tif
