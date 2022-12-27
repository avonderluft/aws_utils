# frozen_string_literal: true

require 'lambda_utils'
aws_lambda = YAML.unsafe_load(File.read("#{fixtures_dir}/aws_lambda.yaml"))

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
    before do
      allow(AwsUtils).to receive(:cached?).with('lambdas').and_return(false)
      lambs_array = [Lambda.new(aws_lambda, 'us-west-2')]
      allow_any_instance_of(LambdaUtils).to receive(:lambdas).and_return(lambs_array)
    end

    it_behaves_like 'a LambdaUtils object'
  end
end

RSpec.describe Lambda do
  subject(:lambda_obj) { described_class.new(aws_lambda, 'us-west-2') }

  describe '#initialize' do
    it "has the attributes of an instance of #{described_class}" do
      %w[arn region name description].each do |ivar|
        expect(lambda_obj.send(ivar)).to be_a(String)
      end
      expect(lambda_obj.env_vars).to be_a(Hash)
    end
  end
end
