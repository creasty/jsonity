require 'forwardable'
require 'jsonity/version'
require 'jsonity/formatter'
require 'jsonity/builder'
require 'jsonity/core_ext'
require 'jsonity/rails' if defined? Rails

module Jsonity

  extend Forwardable

  OBJECT_SUFFIX = /[?!]$/

  ## errors
  class RequiredBlockError < StandardError; end
  class UnexpectedNodeOnArrayError < StandardError; end

  ## shortcut
  def_delegator Builder, :build
  module_function :build

end
