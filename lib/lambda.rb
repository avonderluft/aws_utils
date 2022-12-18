# frozen_string_literal: true

# to contain data from an AWS Lambda
class Lambda
  attr_reader :arn, :name, :description, :runtime, :role, :env_vars, :region, :modified

  def initialize(lamb, region_name)
    p lamb
    @arn = lamb.function_arn
    @name = lamb.function_name
    @description = lamb.description
    @runtime = lamb.runtime
    @role = lamb.role
    @env_vars = lamb.environment ? lamb.environment.variables : {}
    @region = region_name
    @modified = lamb.last_modified
  end

  def output_summary
    puts DIVIDER
    ap summary, indent: -2, multiline: true, color: { string: state_color }
  end

  private

  def state_color
    'light_green'
  end

  def summary
    { ARN: arn, Name: name, Desc: description, Runtime: runtime, Role: role,
      ENV_vars: env_vars, Modified: modified }
  end
end
