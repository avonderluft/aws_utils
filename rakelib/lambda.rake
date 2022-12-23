# frozen_string_literal: true

require_relative '../lib/lambda_utils'

desc 'Show all lambdas by region'
task :lambdas do
  check_cache
  LambdaUtils.new.show_by_regions('all')
end

namespace :lambdas do
  LAMBDA_RUNTIMES.each do |filter|
    desc "Show all lambdas running #{filter} runtime"
    task filter.to_sym do
      check_cache
      LambdaUtils.new.show_by_regions(filter)
    end
  end
end
