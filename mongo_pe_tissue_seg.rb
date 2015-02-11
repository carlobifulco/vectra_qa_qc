
class TissueSeg
  include MongoMapper::Document
  include DataUtilities
  safe
  timestamps!
  after_create :hpf_id_create, :case_id_create
  key :hpf_id, String
  key :case_id, String
  key :tissue_category, String
  key :region_area_pixels, Integer

  key :alexa_514_max_normalized_counts_total_weighting, String
  key :alexa_514_mean_normalized_counts_total_weighting, String
  key :alexa_514_min_normalized_counts_total_weighting, String
  key :alexa_514_std_dev_normalized_counts_total_weighting, String
  key :alexa_514_total_normalized_counts_total_weighting, String
  key :alexa_594_max_normalized_counts_total_weighting, String
  key :alexa_594_mean_normalized_counts_total_weighting, String
  key :alexa_594_min_normalized_counts_total_weighting, String
  key :alexa_594_std_dev_normalized_counts_total_weighting, String
  key :alexa_594_total_normalized_counts_total_weighting, String
  key :autofluorescence_max_normalized_counts_total_weighting, String
  key :autofluorescence_mean_normalized_counts_total_weighting, String
  key :autofluorescence_min_normalized_counts_total_weighting, String
  key :autofluorescence_std_dev_normalized_counts_total_weighting, String
  key :autofluorescence_total_normalized_counts_total_weighting, String
  key :coumarin_max_normalized_counts_total_weighting, String
  key :coumarin_mean_normalized_counts_total_weighting, String
  key :coumarin_min_normalized_counts_total_weighting, String
  key :coumarin_std_dev_normalized_counts_total_weighting, String
  key :coumarin_total_normalized_counts_total_weighting, String
  key :cy3_max_normalized_counts_total_weighting, String
  key :cy3_mean_normalized_counts_total_weighting, String
  key :cy3_min_normalized_counts_total_weighting, String
  key :cy3_std_dev_normalized_counts_total_weighting, String
  key :cy3_total_normalized_counts_total_weighting, String
  key :cy5_max_normalized_counts_total_weighting, String
  key :cy5_mean_normalized_counts_total_weighting, String
  key :cy5_min_normalized_counts_total_weighting, String
  key :cy5_std_dev_normalized_counts_total_weighting, String
  key :cy5_total_normalized_counts_total_weighting, String
  key :dapi_max_normalized_counts_total_weighting, String
  key :dapi_mean_normalized_counts_total_weighting, String
  key :dapi_min_normalized_counts_total_weighting, String
  key :dapi_std_dev_normalized_counts_total_weighting, String
  key :dapi_total_normalized_counts_total_weighting, String
  key :distance_from_process_region_edge_pixels, String
  key :fitc_max_normalized_counts_total_weighting, String
  key :fitc_mean_normalized_counts_total_weighting, String
  key :fitc_min_normalized_counts_total_weighting, String
  key :fitc_std_dev_normalized_counts_total_weighting, String
  key :fitc_total_normalized_counts_total_weighting, String
  key :inform_21543024864, String
  key :lab_id, String
  key :path, String
  key :process_region_id, String
  key :region_area_percent, String

  key :region_axis_ratio, String
  key :region_compactness, String
  key :region_id, String
  key :region_major_axis, String
  key :region_minor_axis, String
  key :region_x_position, String
  key :region_y_position, String
  key :sample_name, String
  key :slide_id, String

  key :tma_column, Integer
  key :tma_field, Integer
  key :tma_row, Integer
  key :tma_sector, Integer
  key :total_regions, Integer

  def hpf_id_create
    self.hpf_id=/.*\]/.match(self.sample_name).to_s.gsub(" ","_").gsub(".im3","")
  end

  def case_id_create
    m=/(.*)_HP.*/.match(self.hpf_id)
    self.case_id=m[1].to_s if m
  end

  def self.get_region_area region_name, hpf_id
    #self.find_all_by_case_id_and_by_tissue_category case_id,region_name
    self.find_all_by_tissue_category_and_case_id region_name,case_id
  end

end
