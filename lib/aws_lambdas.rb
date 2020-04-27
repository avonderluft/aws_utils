# frozen_string_literal: true

require_relative 'aws_lambda'

module AwsLambdas
  def aws_lambdas
    @aws_lambdas ||= begin
      if cached?('aws_lambdas')
        all_aws_lambdas = read_cache('aws_lambdas')
      else
        all_aws_lambdas = []
        region_names.each do |region_name|
          client = Aws::Lambda::Client.new(region: region_name)
          lambdas = client.list_functions.functions
          lambdas.each do |lamb|
            aws_lambda = AwsLambda.new(lamb, region_name)
            all_aws_lambdas << aws_lambda
          end
        end
        write_cache('aws_lambdas', all_aws_lambdas)
      end
      all_aws_lambdas
    end
  end

  def aws_lambdas_by_region(region)
    aws_lambdas.select { |s| s.region == region }
  end
end
