require 'set'

module Jsonity
  module Attribute
    module ClassMethods

      ###
      # Automatically export attributes to json
      #
      # @params {[String | Symbol]} *attrs
      ###
      def attr_json(*attrs)
        @json_attributes ||= Set.new
        @json_attributes |= attrs.map(&:to_s)
      end

      ###
      # Get json attributes
      #
      # @return {[String]}
      ###
      def json_attributes
        @json_attributes.to_a
      end
    end

    module InstanceMethods

      ###
      # Get json attributes
      #
      # @return {[String]}
      ###
      def json_attributes
        self.class.json_attributes
      end

    end
  end
end
