require_relative '../lib/guides_style_18f/generated_nodes'
require_relative '../lib/guides_style_18f/navigation'

require 'minitest/autorun'

module GuidesStyle18F
  # rubocop:disable ClassLength
  # rubocop:disable MethodLength
  class GeneratedNodesTest < ::Minitest::Test
    def setup
    end

    def generate_url_map(nav_data)
      NavigationMenu.map_nav_items_by_url('/', nav_data).to_h
    end

    def page_nav(url, text, generated: false, children: nil, orphan: false)
      nav = {
        'url' => url,
        'text' => text,
        'internal' => true,
      }
      nav['generated'] = true if generated
      nav['children'] = children if children
      nav[:orphan_url] = url if orphan
      nav
    end

    def test_empty_nav_data
      nav_data = []
      url_to_nav = generate_url_map(nav_data)
      GeneratedNodes.create_homes_for_orphans(url_to_nav, nav_data)
      assert_empty(nav_data)
    end

    def test_single_home_page_nav_entry
      nav_data = [page_nav('/', 'Introduction')]
      url_to_nav = generate_url_map(nav_data)
      GeneratedNodes.create_homes_for_orphans(url_to_nav, nav_data)
      assert_equal([page_nav('/', 'Introduction')], nav_data)
    end

    def test_single_orphan
      nav_data = [page_nav('/foo/bar/', 'Bar info', orphan: true)]
      url_to_nav = generate_url_map(nav_data)
      GeneratedNodes.create_homes_for_orphans(url_to_nav, nav_data)
      assert_equal(
        [page_nav(
          'foo/', 'Foo',
          generated: true,
          children: [page_nav('bar/', 'Bar info')])
        ],
        nav_data)
    end

    def test_multiple_orphans
      nav_data = [
        page_nav('/foo/bar/', 'Bar info', orphan: true),
        page_nav('/foo/baz/', 'Baz info', orphan: true),
        page_nav('/foo/quux/', 'Quux info', orphan: true),
      ]
      url_to_nav = generate_url_map(nav_data)
      GeneratedNodes.create_homes_for_orphans(url_to_nav, nav_data)
      assert_equal(
        [page_nav(
          'foo/', 'Foo',
          generated: true,
          children: [
            page_nav('bar/', 'Bar info'),
            page_nav('baz/', 'Baz info'),
            page_nav('quux/', 'Quux info'),
          ])
        ],
        nav_data)
    end

    def test_nested_orphan
      nav_data = [page_nav('/foo/bar/baz/', 'Baz info', orphan: true)]
      url_to_nav = generate_url_map(nav_data)
      GeneratedNodes.create_homes_for_orphans(url_to_nav, nav_data)
      assert_equal(
        [page_nav(
          'foo/', 'Foo',
          generated: true,
          children: [
            page_nav(
              'bar/', 'Bar',
              generated: true,
              children: [page_nav('baz/', 'Baz info')])
          ])
        ],
        nav_data)
    end

    def test_remove_stale_nav_entries_does_not_remove_generated_parent_nodes
      nav_data = [
        page_nav(
          'foo/', 'Foo',
          generated: true,
          children: [
            page_nav(
              'bar/', 'Bar',
              generated: true,
              children: [page_nav('baz/', 'Baz info')])
          ])
      ]
      url_to_nav = generate_url_map(nav_data)
      updated = { '/foo/bar/baz/': true }
      refute_empty(
        NavigationMenu.remove_stale_nav_entries(nav_data, url_to_nav, updated))
    end

    def test_childless_parent_nodes_are_pruned
      nav_data = [
        page_nav(
          'foo/', 'Foo',
          generated: true,
          children: [page_nav('bar/', 'Bar', generated: true)]
        )
      ]

      url_to_nav = generate_url_map(nav_data)
      GeneratedNodes.create_homes_for_orphans(url_to_nav, nav_data)
      assert_empty(nav_data)
    end

    def test_intermediate_non_generated_nodes_are_utilized
      nav_data = [
        page_nav('/foo/bar/', 'Bar info', orphan: true),
        page_nav('/foo/bar/baz/', 'Baz info', orphan: true),
      ]
      url_to_nav = generate_url_map(nav_data)
      GeneratedNodes.create_homes_for_orphans(url_to_nav, nav_data)
      assert_equal(
        [page_nav(
          'foo/', 'Foo',
          generated: true,
          children: [
            page_nav(
              'bar/', 'Bar info',
              children: [page_nav('baz/', 'Baz info')])
          ])
        ],
        nav_data)
    end

    def test_replace_existing_generated_node_with_new_page_node
      nav_data = [
        page_nav(
          'foo/', 'Foo',
          generated: true,
          children: [
            page_nav(
              'bar/', 'Bar',
              generated: true,
              children: [page_nav('baz/', 'Baz info')])
          ])
      ]
      url_to_nav = generate_url_map(nav_data)
      updated = {
        '/foo/' => page_nav('foo/', 'Foo info'),
        '/foo/bar/baz/' => page_nav('baz/', 'Baz info'),
      }

      NavigationMenu.remove_stale_nav_entries(nav_data, url_to_nav, updated)
      updated.map do |url, nav|
        NavigationMenu.apply_nav_update(url, nav, nav_data, url_to_nav)
      end

      GeneratedNodes.create_homes_for_orphans(url_to_nav, nav_data)
      assert_equal(
        [
          page_nav(
            'foo/', 'Foo info',
            children: [
              page_nav(
                'bar/', 'Bar',
                generated: true,
                children: [page_nav('baz/', 'Baz info')])
            ])
        ],
        nav_data)
    end
  end
  # rubocop:enable MethodLength
  # rubocop:enable ClassLength
end
