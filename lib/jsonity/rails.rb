module ActionController
  class Base

    def render_json(options = {}, &block)
      json = Jsonity::Builder.build &block
      options[:json] = json
      render options
    end

  end
end
