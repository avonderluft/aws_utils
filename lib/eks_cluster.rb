# frozen_string_literal: true

# to contain data from an AWS EKS cluster
class EksCluster
  attr_reader :name, :region, :arn, :endpoint, :created, :k8s_version, :eks_version,
              :status, :nodegroups, :logging_types, :tags

  def initialize(cluster, region, client)
    @name = cluster.name
    @region = region
    @arn = cluster.arn
    @endpoint = cluster.endpoint
    @created = cluster.created_at
    @k8s_version = cluster.version
    @eks_version = cluster.platform_version
    @status = cluster.status
    @nodegroups = fetch_nodegroups(client)
    @logging_types = cluster.logging.cluster_logging.first.types
    @tags = cluster.tags
  end

  def status_color
    case status
    when 'ACTIVE', 'CREATING'              then 'light_green'
    when 'DELETING', 'UPDATING', 'PENDING' then 'yellow'
    when 'FAILED'                          then 'light_red'
    else
      'cyan'
    end
  end

  def output_summary
    puts DIVIDER
    ap summary, indent: -2, multiline: true, color: { string: status_color }
  end

  private

  def fetch_nodegroups(eks_client)
    ngs_resp = eks_client.list_nodegroups cluster_name: name
    ngs_resp.nodegroups
  end

  def summary
    { Name: name, ARN: arn, Endpoint: endpoint, Created: created,
      Kubernetes_version: k8s_version, EKS_version: eks_version,
      Status: status.downcase, Nodegroups: nodegroups, Logging_on: logging_types.join(' '),
      Tags: tags }
  end
end
