# frozen_string_literal: true

require 'aws-sdk-eks'
require_relative 'aws_utils'
require_relative 'aws_utils/eks_cluster'

# to query AWS EKS clusters
class EksUtils < AwsUtils
  def eks_client
    @eks_client ||= Aws::EKS::Client.new region: default_region
  end

  def eks_clusters
    @eks_clusters ||= begin
      if AwsUtils.cached?('eks_clusters')
        all_clusters = AwsUtils.read_cache('eks_clusters')
      else
        all_clusters = []
        region_names.each do |region_name|
          eks_reg_client = Aws::EKS::Client.new region: region_name
          eks_reg_client.list_clusters.clusters.each do |cluster_name|
            eks_resp = eks_reg_client.describe_cluster name: cluster_name
            eksc = EksCluster.new(eks_resp.cluster, region_name, eks_reg_client)
            all_clusters << eksc
          end
        rescue Aws::EKS::Errors::AccessDeniedException
          next
        end
        AwsUtils.write_cache('eks_clusters', all_clusters)
      end
      all_clusters
    end
  end

  def show_clusters
    puts LINE
    puts EKS_LEGEND
    eks_clusters.each { |o| output_object(o, o.status_color) }
    puts LINE
    puts EKS_LEGEND
    puts DIVIDER
    puts "EKS Clusters: #{eks_clusters.count.to_s.warning}"
  end

  def show_by_regions(filter = 'all')
    output_by_region(eks_clusters, filter, clusters_filter(filter), EKS_LEGEND)
    # puts ec2_detail_instructions
  end

  private

  def clusters_filter(filter)
    case filter
    when 'all' then eks_clusters
    end
  end
end
