# frozen_string_literal: true

class AwsLambda
  attr_reader :arn, :name, :region, :description, :runtime, :role, :env_vars, :modified

  def initialize(lamb, region_name)
    @arn = lamb.function_arn
    @name = lamb.function_name
    @description = lamb.description
    @runtime = lamb.runtime
    @role = lamb.role
    @env_vars = lamb.environment ? lamb.environment.variables : {}
    @region = region_name
    @modified = lamb.last_modified
  end
end
