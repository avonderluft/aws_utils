# frozen_string_literal: true

require 'colorize'

# aliasing some colorize methods
class String
  alias caution  light_yellow
  alias direct   green
  alias error    light_red
  alias filter   light_magenta
  alias go       light_green
  alias info     green
  alias identify cyan
  alias locale   light_cyan
  alias line     light_blue
  alias off      light_red
  alias running  light_green
  alias status   light_cyan
  alias warning  yellow
end
