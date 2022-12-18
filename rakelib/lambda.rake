# frozen_string_literal: true

require_relative '../lib/lambda_utils'

desc 'Show all Lambdas by region'
task :lambdas do
  check_cache
  LambdaUtils.new.show_by_regions('all')
end

namespace :lambdas do
  %w[].each do |filter|
    desc "Show all #{filter} Lambdas"
    task filter.to_sym do
      check_cache
      LambdaUtils.new.show_by_regions(filter)
    end
  end
end
