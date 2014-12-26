module Jsonity
  class Builder < BasicObject

    ###
    # Build Jsonity
    #
    # @params {Object} object - [optional]
    # @params {Hash<Object, Object> | nil} content - [optional]
    # @block
    #
    # @return {Hash<String, Object>} - json object
    ###
    def self.build(object = nil, content = nil, &block)
      content = {} unless content.is_a?(::Hash)
      builder = new object, content

      if object.respond_to? :json_attributes
        object.json_attributes.each { |a| builder.__send__(:attribute, a, {}) }
      end

      if object.respond_to? :json_attribute_blocks
        object.json_attribute_blocks.each { |b| builder.(&b) }
      end

      builder.(&block)
      builder._content
    end

    ###
    # Initializer
    #
    # @params {Object} object
    # @params {Hash<Object, Object> | nil} content
    ###
    def initialize(object, content)
      @object, @content = object, content
      @deferred_array_blocks = {}
    end

    ###
    # Set `obj` for the object
    #
    # @return {Object}
    ###
    def <=(obj)
      @object = obj
    end

    ###
    # Get the object
    #
    # @return {Object}
    ###
    def get
      @object
    end

    ###
    # Create array context
    #
    # @return {Jsonity::Builder} - `self`
    ###
    def []
      @array = true
      self
    end

    ###
    # Mixin / Scoping
    #
    # @params {Object} obj - [optional]
    # @block
    ###
    def call(obj = nil, &block)
      if obj
        Builder.build obj, @content, &block
      else
        block_call block, self
      end
    end

    ###
    # Getter for `@content`
    #
    # @return {Hash<Object, Object> | nil}
    ###
    def _content
      evaluate_array_blocks!
      @content
    end


  private

    ###
    # Handle ghost methods
    #
    # @params {Symbol} name
    # @params {Array<Object>} args
    # @block block - [optional]
    ###
    def method_missing(name, *args, &block)
      name = name.to_s
      is_object = name.match OBJECT_SUFFIX
      name, is_object = name[0..-2], is_object[0] if is_object

      options = args.last.is_a?(::Hash) ? args.pop.dup : {}
      options[:_object] = args[0]
      options[:_nullable] = ('?' == is_object)

      if @array
        @array = false

        if is_object
          array name, options, &block
        else
          ::Kernel.raise UnexpectedNodeOnArrayError.new("Unexpected attribute node `#{name}`")
        end
      else
        if is_object
          hash name, options, &block
        else
          attribute name, options, &block
        end
      end

      self
    end

    ###
    # Create attribute node
    #
    # @params {String} name
    # @params {Hash<Symbol, Object>} options
    # @block block - [optional]
    ###
    def attribute(name, options, &block)
      return unless on_condition options

      obj = get_object_for name, options

      value = block ? block_call(block, options[:_object] || @object) : obj
      @content[name] = Formatter.format value, name
    end

    ###
    # Create hash node
    #
    # @params {String} name
    # @params {Hash<Symbol, Object>} options
    # @block block - [optional]
    ###
    def hash(name, options, &block)
      return unless on_condition options

      obj = get_object_for name, options

      if options[:_nullable] && !obj
        @content[name] ||= nil
      else
        @content[name] = {} unless @content[name].is_a?(::Hash)
        block ||= ->(t) {}
        Builder.build obj, @content[name], &block
      end
    end

    ###
    # Create array node
    #
    # @params {String} name
    # @params {Hash<Symbol, Object>} options
    # @block block - [optional]
    ###
    def array(name, options, &block)
      return unless on_condition options

      block ||= ->(t) {}

      if (deferred = @deferred_array_blocks[name])
        deferred[:blocks] << block
        return
      end

      obj = get_object_for name, options

      if !obj && options[:_nullable]
        @content[name] ||= nil
      else
        @content[name] = [] unless @content[name].is_a?(::Array)
      end

      if obj
        @deferred_array_blocks[name] = {
          obj:    obj.to_a,
          blocks: [block],
        }
      end
    end

    ###
    # Evaluate all deferred blocks of array nodes,
    # and reset block stack
    ###
    def evaluate_array_blocks!
      @deferred_array_blocks.each do |name, d|
        next unless d[:obj]

        ary = @content[name]

        d[:obj].each.with_index do |a, i|
          d[:blocks].each do |block|
            ary[i] = Builder.build a, ary[i], &block
          end
        end
      end

      @deferred_array_blocks = {}
    end

    ###
    # Get object
    #
    # @params {String} name
    # @params {Hash<Symbol, Object>} options
    #
    # @return {Object}
    ###
    def get_object_for(name, options)
      if options[:_object]
        options[:_object]
      elsif options[:inherit]
        @object
      elsif @object.respond_to? name
        @object.public_send name
      end
    end

    ###
    # Arity safe proc call
    #
    # @params {Proc} block
    # @params {Array<Object>} *args
    #
    # @return {Object}
    ###
    def block_call(block, *args)
      ::Kernel.raise RequiredBlockError.new('No block') unless block

      block.call *args.first(block.arity.abs)
    end

    ###
    # On condition
    #
    # @params {Hash<Symbol, Object>} options
    # @params {Object} obj
    ###
    def on_condition(options, obj = @object)
      flag = true
      flag &&= block_call(options[:if], obj) if options[:if]
      flag &&= !block_call(options[:unless], obj) if options[:unless]
      flag
    end

  end
end
