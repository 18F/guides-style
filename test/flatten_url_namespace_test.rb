require_relative '../lib/guides_style_18f/generator'

require 'minitest/autorun'

module GuidesStyle18F
  class DummySite
    attr_accessor :config, :layouts, :static_files, :collections

    def initialize
      @config = {}
      @layouts = {}
      @static_files = []
      @collections = {}
    end
  end

  class FlattenUrlNamespaceTest < ::Minitest::Test
    attr_accessor :site, :generator

    def setup
      @site = DummySite.new
      @generator = Generator.new
    end

    def test_empty_data
      generator.generate(site)
      assert_nil(site.collections['docs'])
    end
  end
end
