module GuidesStyle18F
  class DummySite
    attr_accessor :config, :layouts, :static_files, :collections
    attr_accessor :permalink_style

    def initialize
      @config = {}
      @layouts = {}
      @static_files = []
      @collections = {}
      @permalink_style = 'pretty'
    end

    def site_payload
      {}
    end

    def converters
      []
    end
  end
end
