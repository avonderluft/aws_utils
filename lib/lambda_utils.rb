# frozen_string_literal: true

require 'aws-sdk-lambda'
require_relative 'lambda'

# to query AWS Lambdas
class LambdaUtils < AwsUtils
  include Ec2Regions

  def lambdas
    @lambdas ||= begin
      if AwsUtils.cached?('lambdas')
        all_lambdas = AwsUtils.read_cache('lambdas')
      else
        all_lambdas = []
        region_names.each do |region_name|
          client = Aws::Lambda::Client.new(region: region_name)
          begin
            lambdas = client.list_functions.functions
          rescue Aws::Lambda::Errors::AccessDeniedException
            next
          end
          lambdas.each do |lamb|
            aws_lambda = Lambda.new(lamb, region_name)
            all_lambdas << aws_lambda
          end
        end
        AwsUtils.write_cache('lambdas', all_lambdas)
      end
      all_lambdas
    end
  end

  def show_by_regions(filter)
    output_by_region(lambdas, filter, lambdas_filter(filter), '')
  end

  private

  def lambdas_filter(filter)
    if LAMBDA_RUNTIMES.include? filter
      lambdas.select { |l| l.runtime.start_with? filter }
    else
      case filter
      when 'all' then lambdas
      end
    end
  end
end
