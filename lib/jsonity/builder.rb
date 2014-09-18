module Jsonity
  class Builder < BasicObject

    ###
    # Build Jsonity
    #
    # @params {any} object - [optional]
    # @params {Hash | nil} content - [optional]
    # @block
    #
    # @return {Hash} - json object
    ###
    def self.build(object = nil, content = nil, &block)
      content = {} unless content.is_a?(::Hash)
      builder = new object, content

      if object.respond_to? :json_attributes
        object.json_attributes.each { |a| builder.__send__ :attribute, a, nil }
      end

      builder.(&block)
      builder.__send__ :content
    end

    ###
    # Initializer
    #
    # @params {any} object
    # @params {Hash | nil} content
    ###
    def initialize(object, content)
      @object, @content = object, content
      @deferred_array_blocks = {}
    end

    ###
    # Set `obj` for the object
    ###
    def <=(obj)
      @object = obj
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
    # @params {any} obj - [optional]
    # @block
    ###
    def call(obj = nil, &block)
      if obj
        Builder.build obj, @content, &block
      else
        block_call block, self, @object
      end
    end


  private

    ###
    # Handle ghost methods
    ###
    def method_missing(name, *args, &block)
      name = name.to_s
      is_object = name.match OBJECT_SUFFIX
      name, is_object = name[0..-2], is_object[0] if is_object

      options = args.last.is_a?(::Hash) ? args.pop : {}
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
    # Getter for `@content`
    #
    # @return {Hash | nil}
    ###
    def content
      evaluate_array_blocks!
      @content
    end

    ###
    # Create attribute node
    #
    # @params {String} name
    # @params {Hash} options
    # @block - [optional]
    ###
    def attribute(name, options, &block)
      obj = get_object_for name, options

      @content[name] = block ? block_call(block, obj || @object) : obj
    end

    ###
    # Create hash node
    #
    # @params {String} name
    # @params {Hash} options
    # @block - [optional]
    ###
    def hash(name, options, &block)
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
    # @params {Hash} options
    # @block
    ###
    def array(name, options, &block)
      ::Kernel.raise RequiredBlockError.new('No block') unless block

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
    # @params {Hash} options - [optional]
    #
    # @return {any}
    ###
    def get_object_for(name, options = nil)
      if options && options[:_object]
        options[:_object]
      elsif options && options[:inherit]
        @object
      elsif @object.respond_to? name
        @object.public_send name
      end
    end

    ###
    # Arity safe proc call
    #
    # @params {Proc} block
    # @params {[any]} *args
    #
    # @return {any}
    ###
    def block_call(block, *args)
      ::Kernel.raise RequiredBlockError.new('No block') unless block

      block.call *args.first(block.arity)
    end

  end
end
