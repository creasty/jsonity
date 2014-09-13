module ActionController
  class Base

    protected

    def render_json(*args, &block)
      options = args.extract_options!
      json = Jsonity::Builder.build args[0], &block
      options[:json] = json
      render options
    end

  end
end
