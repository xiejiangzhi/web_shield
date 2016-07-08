module WebShield
  class Shield
    def initialize(path, options)
      @route = build_path_matcher(path)
    end


    private

    def build_path_matcher(path)
      ActionDispatch::Journey::Router::Strexp.compile(
        path, {}, ActionDispatch::Routing::SEPARATORS
      )
      ActionDispatch::Journey::Path::Pattern.new(strexp)
    end
  end
end

