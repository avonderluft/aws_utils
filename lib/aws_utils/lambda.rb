# frozen_string_literal: true

# to contain data from an AWS Lambda
class Lambda
  attr_reader :arn, :region, :name, :description, :runtime, :role, :env_vars, :modified

  def initialize(lamb, region_name)
    @arn = lamb.function_arn
    @region = region_name
    @name = lamb.function_name
    @description = lamb.description
    @runtime = lamb.runtime
    @role = lamb.role
    @env_vars = lamb.environment ? lamb.environment.variables : {}
    @modified = lamb.last_modified
  end

  def output_summary
    puts DIVIDER
    ap summary, indent: -2, multiline: true, color: { string: status_color }
  end

  private

  def status_color
    # %w[dotnet go java node python ruby]
    case runtime[0, 2]
    when 'do' then 'light_blue'
    when 'go' then 'light_cyan'
    when 'ja' then 'cyan'
    when 'no' then 'light_green'
    when 'py' then 'yellow'
    when 'ru' then 'light_red'
    end
  end

  def summary
    { ARN: arn, Name: name, Desc: description, Runtime: runtime, Role: role,
      ENV_vars: env_vars, Modified: modified }
  end
end
