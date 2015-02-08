require_relative "analyzer"
require "rserve"
require_relative "loader"



class CaseData
  include MongoMapper::Document
  include DataUtilities
  safe
  timestamps!
  many :cell_seg
  many :hpf_image
  key :case_id, String

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
  def plot_simple
    jpeg_file_name=self.cell_seg_data_summary_table_path.gsub(".csv",".jpeg")
    r_command="
    jpeg(file='#{jpeg_file_name}')
    library('ggplot2', lib.loc='/Library/Frameworks/R.framework/Versions/3.1/Resources/library')
    d= read.csv('#{self.cell_seg_data_summary_table_path}', stringsAsFactors=FALSE)
    w=summary(factor(d$phenotype))
    w=data.frame(w)
    print(qplot(rownames(w), w$w)+coord_flip()+ylab('counts')+xlab('cell types'))
    dev.off()
    "
    puts r_command
    begin
      Rserve::Connection.new.eval(r_command)
      `open #{jpeg_file_name}`
    rescue Rserve::Connection::RserveNotStartedError
    end
  end
end

class CellSeg
  include MongoMapper::Document
  include DataUtilities
  safe
  timestamps!
  after_create :hpf_id_create, :case_id_create
  belongs_to :case_data
  key :hpf_id, String
  key :case_id, String
  #matches in table
  key :category_region_id, Integer
  key :cell_density_per_megapixel, String
  key :cell_id, Integer
  key :cell_x_position, Integer
  key :cell_y_position, Integer
  key :confidence, String
  key :cytoplasm_alexa_514_max_normalized_counts_total_weighting, Float
  key :cytoplasm_alexa_514_mean_normalized_counts_total_weighting, Float
  key :cytoplasm_alexa_514_min_normalized_counts_total_weighting, Float
  key :cytoplasm_alexa_514_std_dev_normalized_counts_total_weighting, Float
  key :cytoplasm_alexa_514_total_normalized_counts_total_weighting, Float
  key :cytoplasm_alexa_594_max_normalized_counts_total_weighting, Float
  key :cytoplasm_alexa_594_mean_normalized_counts_total_weighting, Float
  key :cytoplasm_alexa_594_min_normalized_counts_total_weighting, Float
  key :cytoplasm_alexa_594_std_dev_normalized_counts_total_weighting, Float
  key :cytoplasm_alexa_594_total_normalized_counts_total_weighting, Float
  key :cytoplasm_area_percent, String
  key :cytoplasm_area_pixels, Integer
  key :cytoplasm_autofluorescence_max_normalized_counts_total_weighting, Float
  key :cytoplasm_autofluorescence_mean_normalized_counts_total_weighting, Float
  key :cytoplasm_autofluorescence_min_normalized_counts_total_weighting, Float
  key :cytoplasm_autofluorescence_std_dev_normalized_counts_total_weighting, Float
  key :cytoplasm_autofluorescence_total_normalized_counts_total_weighting, Float
  key :cytoplasm_axis_ratio, Float
  key :cytoplasm_compactness, Float
  key :cytoplasm_coumarin_max_normalized_counts_total_weighting, Float
  key :cytoplasm_coumarin_mean_normalized_counts_total_weighting, Float
  key :cytoplasm_coumarin_min_normalized_counts_total_weighting, Float
  key :cytoplasm_coumarin_std_dev_normalized_counts_total_weighting, Float
  key :cytoplasm_coumarin_total_normalized_counts_total_weighting, Float
  key :cytoplasm_cy3_max_normalized_counts_total_weighting, Float
  key :cytoplasm_cy3_mean_normalized_counts_total_weighting, Float
  key :cytoplasm_cy3_min_normalized_counts_total_weighting, Float
  key :cytoplasm_cy3_std_dev_normalized_counts_total_weighting, Float
  key :cytoplasm_cy3_total_normalized_counts_total_weighting, Float
  key :cytoplasm_cy5_max_normalized_counts_total_weighting, Float
  key :cytoplasm_cy5_mean_normalized_counts_total_weighting, Float
  key :cytoplasm_cy5_min_normalized_counts_total_weighting, Float
  key :cytoplasm_cy5_std_dev_normalized_counts_total_weighting, Float
  key :cytoplasm_cy5_total_normalized_counts_total_weighting, Float
  key :cytoplasm_dapi_max_normalized_counts_total_weighting, Float
  key :cytoplasm_dapi_mean_normalized_counts_total_weighting, Float
  key :cytoplasm_dapi_min_normalized_counts_total_weighting, Float
  key :cytoplasm_dapi_std_dev_normalized_counts_total_weighting, Float
  key :cytoplasm_dapi_total_normalized_counts_total_weighting, Float
  key :cytoplasm_fitc_max_normalized_counts_total_weighting, Float
  key :cytoplasm_fitc_mean_normalized_counts_total_weighting, Float
  key :cytoplasm_fitc_min_normalized_counts_total_weighting, Float
  key :cytoplasm_fitc_std_dev_normalized_counts_total_weighting, Float
  key :cytoplasm_fitc_total_normalized_counts_total_weighting, Float
  key :cytoplasm_major_axis, Float
  key :cytoplasm_minor_axis, Float
  key :distance_from_process_region_edge_pixels, String
  key :distance_from_tissue_category_edge_pixels, String
  key :entire_cell_alexa_514_max_normalized_counts_total_weighting, Float
  key :entire_cell_alexa_514_mean_normalized_counts_total_weighting, Float
  key :entire_cell_alexa_514_min_normalized_counts_total_weighting, Float
  key :entire_cell_alexa_514_std_dev_normalized_counts_total_weighting, Float
  key :entire_cell_alexa_514_total_normalized_counts_total_weighting, Float
  key :entire_cell_alexa_594_max_normalized_counts_total_weighting, Float
  key :entire_cell_alexa_594_mean_normalized_counts_total_weighting, Float
  key :entire_cell_alexa_594_min_normalized_counts_total_weighting, Float
  key :entire_cell_alexa_594_std_dev_normalized_counts_total_weighting, Float
  key :entire_cell_alexa_594_total_normalized_counts_total_weighting, Float
  key :entire_cell_area_percent, String
  key :entire_cell_area_pixels, Integer
  key :entire_cell_autofluorescence_max_normalized_counts_total_weighting, Float
  key :entire_cell_autofluorescence_mean_normalized_counts_total_weighting, Float
  key :entire_cell_autofluorescence_min_normalized_counts_total_weighting, Float
  key :entire_cell_autofluorescence_std_dev_normalized_counts_total_weighting, Float
  key :entire_cell_autofluorescence_total_normalized_counts_total_weighting, Float
  key :entire_cell_axis_ratio, Float
  key :entire_cell_compactness, Float
  key :entire_cell_coumarin_max_normalized_counts_total_weighting, Float
  key :entire_cell_coumarin_mean_normalized_counts_total_weighting, Float
  key :entire_cell_coumarin_min_normalized_counts_total_weighting, Float
  key :entire_cell_coumarin_std_dev_normalized_counts_total_weighting, Float
  key :entire_cell_coumarin_total_normalized_counts_total_weighting, Float
  key :entire_cell_cy3_max_normalized_counts_total_weighting, Float
  key :entire_cell_cy3_mean_normalized_counts_total_weighting, Float
  key :entire_cell_cy3_min_normalized_counts_total_weighting, Float
  key :entire_cell_cy3_std_dev_normalized_counts_total_weighting, Float
  key :entire_cell_cy3_total_normalized_counts_total_weighting, Float
  key :entire_cell_cy5_max_normalized_counts_total_weighting, Float
  key :entire_cell_cy5_mean_normalized_counts_total_weighting, Float
  key :entire_cell_cy5_min_normalized_counts_total_weighting, Float
  key :entire_cell_cy5_std_dev_normalized_counts_total_weighting, Float
  key :entire_cell_cy5_total_normalized_counts_total_weighting, Float
  key :entire_cell_dapi_max_normalized_counts_total_weighting, Float
  key :entire_cell_dapi_mean_normalized_counts_total_weighting, Float
  key :entire_cell_dapi_min_normalized_counts_total_weighting, Float
  key :entire_cell_dapi_std_dev_normalized_counts_total_weighting, Float
  key :entire_cell_dapi_total_normalized_counts_total_weighting, Float
  key :entire_cell_fitc_max_normalized_counts_total_weighting, Float
  key :entire_cell_fitc_mean_normalized_counts_total_weighting, Float
  key :entire_cell_fitc_min_normalized_counts_total_weighting, Float
  key :entire_cell_fitc_std_dev_normalized_counts_total_weighting, Float
  key :entire_cell_fitc_total_normalized_counts_total_weighting, Float
  key :entire_cell_major_axis, Float
  key :entire_cell_minor_axis, Float
  key :inform_21543024864, String
  key :lab_id, String
  key :membrane_alexa_514_max_normalized_counts_total_weighting, Float
  key :membrane_alexa_514_mean_normalized_counts_total_weighting, Float
  key :membrane_alexa_514_min_normalized_counts_total_weighting, Float
  key :membrane_alexa_514_std_dev_normalized_counts_total_weighting, Float
  key :membrane_alexa_514_total_normalized_counts_total_weighting, Float
  key :membrane_alexa_594_max_normalized_counts_total_weighting, Float
  key :membrane_alexa_594_mean_normalized_counts_total_weighting, Float
  key :membrane_alexa_594_min_normalized_counts_total_weighting, Float
  key :membrane_alexa_594_std_dev_normalized_counts_total_weighting, Float
  key :membrane_alexa_594_total_normalized_counts_total_weighting, Float
  key :membrane_area_percent, String
  key :membrane_area_pixels, Integer
  key :membrane_autofluorescence_max_normalized_counts_total_weighting, Float
  key :membrane_autofluorescence_mean_normalized_counts_total_weighting, Float
  key :membrane_autofluorescence_min_normalized_counts_total_weighting, Float
  key :membrane_autofluorescence_std_dev_normalized_counts_total_weighting, Float
  key :membrane_autofluorescence_total_normalized_counts_total_weighting, Float
  key :membrane_axis_ratio, Float
  key :membrane_compactness, Float
  key :membrane_coumarin_max_normalized_counts_total_weighting, Float
  key :membrane_coumarin_mean_normalized_counts_total_weighting, Float
  key :membrane_coumarin_min_normalized_counts_total_weighting, Float
  key :membrane_coumarin_std_dev_normalized_counts_total_weighting, Float
  key :membrane_coumarin_total_normalized_counts_total_weighting, Float
  key :membrane_cy3_max_normalized_counts_total_weighting, Float
  key :membrane_cy3_mean_normalized_counts_total_weighting, Float
  key :membrane_cy3_min_normalized_counts_total_weighting, Float
  key :membrane_cy3_std_dev_normalized_counts_total_weighting, Float
  key :membrane_cy3_total_normalized_counts_total_weighting, Float
  key :membrane_cy5_max_normalized_counts_total_weighting, Float
  key :membrane_cy5_mean_normalized_counts_total_weighting, Float
  key :membrane_cy5_min_normalized_counts_total_weighting, Float
  key :membrane_cy5_std_dev_normalized_counts_total_weighting, Float
  key :membrane_cy5_total_normalized_counts_total_weighting, Float
  key :membrane_dapi_max_normalized_counts_total_weighting, Float
  key :membrane_dapi_mean_normalized_counts_total_weighting, Float
  key :membrane_dapi_min_normalized_counts_total_weighting, Float
  key :membrane_dapi_std_dev_normalized_counts_total_weighting, Float
  key :membrane_dapi_total_normalized_counts_total_weighting, Float
  key :membrane_fitc_max_normalized_counts_total_weighting, Float
  key :membrane_fitc_mean_normalized_counts_total_weighting, Float
  key :membrane_fitc_min_normalized_counts_total_weighting, Float
  key :membrane_fitc_std_dev_normalized_counts_total_weighting, Float
  key :membrane_fitc_total_normalized_counts_total_weighting, Float
  key :membrane_major_axis, Float
  key :membrane_minor_axis, Float
  key :nucleus_alexa_514_max_normalized_counts_total_weighting, Float
  key :nucleus_alexa_514_mean_normalized_counts_total_weighting, Float
  key :nucleus_alexa_514_min_normalized_counts_total_weighting, Float
  key :nucleus_alexa_514_std_dev_normalized_counts_total_weighting, Float
  key :nucleus_alexa_514_total_normalized_counts_total_weighting, Float
  key :nucleus_alexa_594_max_normalized_counts_total_weighting, Float
  key :nucleus_alexa_594_mean_normalized_counts_total_weighting, Float
  key :nucleus_alexa_594_min_normalized_counts_total_weighting, Float
  key :nucleus_alexa_594_std_dev_normalized_counts_total_weighting, Float
  key :nucleus_alexa_594_total_normalized_counts_total_weighting, Float
  key :nucleus_area_percent, String
  key :nucleus_area_pixels, Integer
  key :nucleus_autofluorescence_max_normalized_counts_total_weighting, Float
  key :nucleus_autofluorescence_mean_normalized_counts_total_weighting, Float
  key :nucleus_autofluorescence_min_normalized_counts_total_weighting, Float
  key :nucleus_autofluorescence_std_dev_normalized_counts_total_weighting, Float
  key :nucleus_autofluorescence_total_normalized_counts_total_weighting, Float
  key :nucleus_axis_ratio, Float
  key :nucleus_compactness, Float
  key :nucleus_coumarin_max_normalized_counts_total_weighting, Float
  key :nucleus_coumarin_mean_normalized_counts_total_weighting, Float
  key :nucleus_coumarin_min_normalized_counts_total_weighting, Float
  key :nucleus_coumarin_std_dev_normalized_counts_total_weighting, Float
  key :nucleus_coumarin_total_normalized_counts_total_weighting, Float
  key :nucleus_cy3_max_normalized_counts_total_weighting, Float
  key :nucleus_cy3_mean_normalized_counts_total_weighting, Float
  key :nucleus_cy3_min_normalized_counts_total_weighting, Float
  key :nucleus_cy3_std_dev_normalized_counts_total_weighting, Float
  key :nucleus_cy3_total_normalized_counts_total_weighting, Float
  key :nucleus_cy5_max_normalized_counts_total_weighting, Float
  key :nucleus_cy5_mean_normalized_counts_total_weighting, Float
  key :nucleus_cy5_min_normalized_counts_total_weighting, Float
  key :nucleus_cy5_std_dev_normalized_counts_total_weighting, Float
  key :nucleus_cy5_total_normalized_counts_total_weighting, Float
  key :nucleus_dapi_max_normalized_counts_total_weighting, Float
  key :nucleus_dapi_mean_normalized_counts_total_weighting, Float
  key :nucleus_dapi_min_normalized_counts_total_weighting, Float
  key :nucleus_dapi_std_dev_normalized_counts_total_weighting, Float
  key :nucleus_dapi_total_normalized_counts_total_weighting, Float
  key :nucleus_fitc_max_normalized_counts_total_weighting, Float
  key :nucleus_fitc_mean_normalized_counts_total_weighting, Float
  key :nucleus_fitc_min_normalized_counts_total_weighting, Float
  key :nucleus_fitc_std_dev_normalized_counts_total_weighting, Float
  key :nucleus_fitc_total_normalized_counts_total_weighting, Float
  key :nucleus_major_axis, Float
  key :nucleus_minor_axis, Float
  key :path, String
  key :phenotype, String
  key :process_region_id, String
  key :sample_name, String
  key :slide_id, String
  key :tissue_category, String
  key :tissue_category_area_pixels, String
  key :tma_column, Integer
  key :tma_field, Integer
  key :tma_row, Integer
  key :tma_sector, Integer
  key :total_cells, String

  def hpf_id_create
    self.hpf_id=/.*\]/.match(self.sample_name).to_s.gsub(" ","_")
  end

  def case_id_create
    m=/(.*)_HP.*/.match(self.hpf_id)
    self.case_id=m[1].to_s if m
  end


end

CellSeg.ensure_index(:hpf_id)
CellSeg.ensure_index(:case_id)
