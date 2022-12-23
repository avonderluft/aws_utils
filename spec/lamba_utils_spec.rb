# frozen_string_literal: true

require 'lambda_utils'

RSpec.shared_examples 'a LambdaUtils object' do
  describe '#lambdas' do
    it 'has lambdas' do
      expect(lambdautils.lambdas).to be_an Array
      expect(lambdautils.lambdas).to_not be_empty
      expect(lambdautils.lambdas).to all be_a(Lambda)
    end
  end

  describe '#show_by_regions' do
    %w[ARN Name Runtime].each do |key|
      it { expect { lambdautils.show_by_regions('all') }.to output(/#{key}/).to_stdout }
    end
    LAMBDA_RUNTIMES.each do |runtime|
      it { expect { lambdautils.show_by_regions(runtime) }.to output(/#{runtime}/).to_stdout }
    end
  end
end

RSpec.describe LambdaUtils do
  subject(:lambdautils) { described_class.new }

  context 'with caching' do
    it_behaves_like 'a LambdaUtils object'
  end

  context 'without caching' do
    pending 'need to set up fixtures and before block'
    it_behaves_like 'a LambdaUtils object'
  end
end
