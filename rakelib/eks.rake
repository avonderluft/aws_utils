# frozen_string_literal: true

require_relative '../lib/eks_utils'

desc 'Show all EKS Clusters'
task :eks do
  check_cache
  EksUtils.new.show_by_regions('all')
end

namespace :eks do
  # TODO
end
