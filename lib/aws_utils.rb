# frozen_string_literal: true

require 'aws-sdk-costexplorer'
require 'aws-sdk-ec2'
require 'aws-sdk-iam'
require 'aws-sdk-lambda'
require 'aws-sdk-rds'
require 'aws-sdk-s3'
require_relative 'aws_setup'
require_relative 'aws_lambdas'
require_relative 'ec2_instances'
require_relative 'ec2_regions'
require_relative 'ec2_snapshots'
require_relative 'ec2_volumes'
require_relative 'iam_users'
require_relative 'kms_keys'
require_relative 's3_buckets'
require_relative 'rds_db_instances'
require_relative 'audit_common'

class AwsUtils
  include AwsSetup
  include AwsLambdas
  include Ec2Instances
  include Ec2Regions
  include Ec2Snapshots
  include Ec2Volumes
  include IamUsers
  include KmsKeys
  include RdsDbInstances
  include S3Buckets

  def initialize(cached = false)
    setup(cached)
  end
end
