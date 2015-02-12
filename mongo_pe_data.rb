require_relative "analyzer"
require "rserve"
require_relative "loader"
require_relative "rserve_connectivity"



class CaseData
  include MongoMapper::Document
  include DataUtilities
  safe
  timestamps!
  many :cell_seg
  many :tissue_seg
  many :hpf_image
  key :case_id, String
  key :plot_densities_pdf_path, String
  key :case_derivative_directory_path, String
  after_create :create_derivative_folder

  def self.get_case case_id
    self.find_by_case_id(case_id) or self.new({:case_id=>case_id})
  end

  def show_simple_plots
    self.hpf_image.each {|x| x.plot_simple}
  end

  def mega_table_path
    return false if self.hpf_image.length==0
    File.dirname(self.hpf_image[0].cell_seg_data_summary_table_path)\
                                  +"/"+self.case_id+"_mega_table.csv"
  end

  def merge_all_cell_seq_tables
    return if not self.mega_table_path
    command=["bio-table"]
    self.hpf_image.each {|x| command << x.cell_seg_data_summary_table_path}
    command<<"> #{self.mega_table_path}"
    command=command.join " "
    puts command
    `#{command}`
  end

  def cell_density_tsv header=false
    r=[]
    self.hpf_image.each do |x|
      r<<x.cell_density_tsv
    end
    (r.prepend("unique_id\tphenotype_compartment\tdensity_cells_mm2")) if header
    r.flatten.join("\n")
  end

  def cell_density_tsv_write  header=false
    file_path="#{CONFIG["WORKING_DIR"]}/#{self.case_id}_total_density_table.tsv"
    File.write(file_path, cell_density_tsv(header))
    file_path
  end

  def show_composite
    self.hpf_image.each {|x| x.show :composite_image}
  end

  def export_derivative
    `cp #{self.plot_densities_pdf_path} #{self.case_derivative_directory_path}`
  end

  def create_derivative_folder
    self.case_derivative_directory_path=CONFIG['DERIVATIVE_FOLDER']+"/"+self.case_id
    Dir.mkdir  self.case_derivative_directory_path unless Dir.exists? self.case_derivative_directory_path
    self.save
    self.case_derivative_directory_path
  end

  def review
    file_list=Dir.glob("#{self.case_derivative_directory_path}/*/**").join " "
    `open #{file_list}`
  end
end


class CaseData
  def plot_densities
    file_path="#{CONFIG["WORKING_DIR"]}/#{self.case_id}_total_density_table.tsv"
    self.cell_density_tsv_write unless File.exists? file_path
    Rserve.connect
    pdf_file_name=file_path.gsub(".tsv",".pdf")
    r_command="
    pdf(file='#{pdf_file_name}')
    library('ggplot2')
    d <- read.delim('#{file_path}')
    print(ggplot(d, aes(phenotype_compartment, density_cells_mm2))+ geom_boxplot()+ theme(axis.text.x =
    element_text(size  = 8,
    angle = 90,
    hjust = 0,
    vjust = 0))+coord_flip()+ ggtitle('#{self.case_id}'))
    dev.off()
    "
    puts r_command
    Rconnect.exec r_command, pdf_file_name
    self.plot_densities_pdf_path=pdf_file_name
    self.save
  end
end

### Image Storage
class HpfImage
  include MongoMapper::Document
  include DataUtilities
  timestamps!
  safe
  belongs_to :case_data
  after_create :hpf_id_create, :case_id_create
  key :file_path, String
  key :hpf_id, String
  key :case_id, String
  key :tissue_seg_data_summary,String
  key :cell_seg_data_summary_table_path,String
  #images
  key :composite_image, String
  key :image_with_cell_seg_map, String
  key :phenotype_map, String
  key :image_with_score_map, String
  key :image_with_tissue_seg,String
  key :phenotype_map, String
  key :tissue_seg_map,String
  key :raw_tif, String

  # derivative images
  key :plot_simple_pdf_path, String
  key :hpf_derivative_directory_path, String
  after_create :create_derivative_folder

  def hpf_id_create
    self.hpf_id=/.*\]/.match(File.basename self.file_path).to_s.gsub(" ","_")
  end

  def case_id_create
    m=/(.*)_HP.*/.match(self.hpf_id)
    self.case_id=m[1].to_s if m
  end

  def self.get_hpf_image file_path
    hpf_id=/.*\]/.match(File.basename file_path).to_s.gsub(" ","_")
    self.find_by_hpf_id(hpf_id) or self.new({:file_path=>file_path})
  end

  def get_tissue_seg region_name
    TissueSeg.find_all_by_tissue_category_and_hpf_id(region_name, self.hpf_id)
  end

  def get_cell_seg region_name, phenotype
    CellSeg.find_all_by_tissue_category_and_phenotype_and_hpf_id(region_name, phenotype, self.hpf_id)
  end

  def cell_density  region_name, phenotype
    cell_count=get_cell_seg(region_name, phenotype).count
    region_area_pixel=get_tissue_seg(region_name)[0][:region_area_pixels]
    region_area_sq_micron=(region_area_pixel/2^2)/1000000.0
    (cell_count/region_area_sq_micron).to_s
  end

  def cell_density_tsv header=false
    r=CONFIG["PHENOTYPES"].map{|x| CONFIG["REGIONS"]\
              .map{|y|["#{self.hpf_id}\t#{x}:#{y}\t#{self.cell_density(y,x)}"]}}\
              .flatten
    (r.prepend("unique_id \ttarget,\tdensity (cells/mm2)")).flatten if header
    r.join("\n")
  end

  def cell_density_tsv_write  header=false
    file_path="#{CONFIG["WORKING_DIR"]}/#{self.hpf_id}_density_table.tsv"
    File.write(file_path, cell_density_tsv(header))
    file_path
  end

  def create_derivative_folder
    return false if self.case_data.case_derivative_directory_path==nil
    self.hpf_derivative_directory_path=self.case_data.case_derivative_directory_path+"/"+self.hpf_id
    Dir.mkdir  self.hpf_derivative_directory_path unless Dir.exists? self.hpf_derivative_directory_path
    self.save
    self.hpf_derivative_directory_path
  end

  def export
    if create_derivative_folder
      `cp #{self.plot_simple_pdf_path} #{self.hpf_derivative_directory_path}`
      `cp #{self.composite_image} #{self.hpf_derivative_directory_path}`
      `cp  #{self.tissue_seg_map} #{self.hpf_derivative_directory_path}`
    else
      puts "NO FOLDER FOR HPF EXPORT, FAILED #{self.hpf_id}".green
    end
  end

  def show image_type
    puts self[image_type.to_sym]
    `open #{self[image_type.to_sym]}`
    sleep 1
  end

  # def show image_type
  #   t_f=Tempfile.new(["#{image_type.to_s+Random.rand.to_s.split(".")[1]}",".png"])
  #   puts t_f.path
  #   t_f.write self[image_type].to_s
  #   t_f.close
  #
  #   #{}`open #{t_f.path}`
  #   sleep 1
  #   #t_f.unlink
  # end

  def show_key
    [:raw_tif, :composite_image, :phenotype_map, :image_with_tissue_seg]\
                .each {|x| self.show x}
    plot_simple
  end
end

### R utilities
class HpfImage
  ### manipulates cell_seg_data
  # note the print wrapper around q plot
  def plot_simple
    pdf_file_name=self.cell_seg_data_summary_table_path.gsub(".csv",".pdf")
    r_command="
    pdf(file='#{pdf_file_name}')
    library('ggplot2')
    d= read.csv('#{self.cell_seg_data_summary_table_path}', stringsAsFactors=FALSE)
    w=summary(factor(d$phenotype))
    w=data.frame(w)
    print(qplot(rownames(w), w$w)+coord_flip()+ylab('counts')+xlab('cell types'))
    dev.off()
    "
    puts r_command
    Rconnect.exec r_command, pdf_file_name
    self.plot_simple_pdf_path=pdf_file_name
    self.save
  end
end
