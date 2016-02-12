require_relative '../lib/guides_style_18f/redirect_nodes'
require_relative '../lib/guides_style_18f/navigation'

require 'minitest/autorun'

module GuidesStyle18F
  class RedirectNodesTest < ::Minitest::Test
    def setup
    end

    def generate_url_map(nav_data)
      NavigationMenu.map_nav_items_by_url('/', nav_data).to_h
    end

    def test_empty_nav_data
      nav_data = []
      original = generate_url_map(nav_data)
      RedirectNodes.create_homes_for_orphans(original, nav_data)
      assert_empty(nav_data)
    end
  end
end
