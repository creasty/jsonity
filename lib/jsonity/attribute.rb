require 'set'

module Jsonity
  module Attribute
    module ClassMethods

      ###
      # Automatically export attributes to json
      #
      # @params {[String | Symbol]} *attrs
      # @block - [optional]
      ###
      def attr_json(*attrs, &block)
        @json_attributes ||= []
        @json_attributes += attrs.map(&:to_s)
        @json_attributes.uniq!

        @json_attribute_blocks ||= []
        @json_attribute_blocks << block if block
      end

      ###
      # Get json attributes
      #
      # @return {[String]}
      ###
      def json_attributes
        @json_attributes || []
      end

      ###
      # Get json attributes
      #
      # @return {[String]}
      ###
      def json_attribute_blocks
        @json_attribute_blocks || []
      end

    end

    module InstanceMethods

      ###
      # Get json attributes (delegates to self class)
      #
      # @return {[String]}
      ###
      def json_attributes
        self.class.json_attributes
      end

      ###
      # Get json attributes (delegates to self class)
      #
      # @return {[String]}
      ###
      def json_attribute_blocks
        self.class.json_attribute_blocks
      end

    end
  end
end
