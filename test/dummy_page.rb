module GuidesStyle18F
  class DummyPage < ::Jekyll::Page
    attr_accessor :data

    def initialize(site, permalink)
      @site = site
      @data = {}
      data['permalink'] = permalink
    end

    def html?
      true
    end
  end
end
