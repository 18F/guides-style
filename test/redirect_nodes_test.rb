require_relative '../lib/guides_style_18f/redirect_nodes'
require_relative '../lib/guides_style_18f/navigation'

require 'minitest/autorun'

module GuidesStyle18F
  # rubocop:disable ClassLength
  # rubocop:disable MethodLength
  class RedirectNodesTest < ::Minitest::Test
    def setup
    end

    def generate_url_map(nav_data)
      NavigationMenu.map_nav_items_by_url('/', nav_data).to_h
    end

    def page_nav(url, text, redirect: false, children: nil, orphan: false)
      nav = {
        'url' => url,
        'text' => text,
        'internal' => true,
      }
      nav['redirect'] = true if redirect
      nav['children'] = children if children
      nav[:orphan_url] = url if orphan
      nav
    end

    def test_empty_nav_data
      nav_data = []
      original = generate_url_map(nav_data)
      RedirectNodes.create_homes_for_orphans(original, nav_data)
      assert_empty(nav_data)
    end

    def test_single_home_page_nav_entry
      nav_data = [page_nav('/', 'Introduction')]
      original = generate_url_map(nav_data)
      RedirectNodes.create_homes_for_orphans(original, nav_data)
      assert_equal([page_nav('/', 'Introduction')], nav_data)
    end

    def test_single_orphan
      nav_data = [page_nav('/foo/bar/', 'Bar info', orphan: true)]
      original = generate_url_map(nav_data)
      RedirectNodes.create_homes_for_orphans(original, nav_data)
      assert_equal(
        [page_nav(
          'foo/', 'Foo',
          redirect: true,
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
      original = generate_url_map(nav_data)
      RedirectNodes.create_homes_for_orphans(original, nav_data)
      assert_equal(
        [page_nav(
          'foo/', 'Foo',
          redirect: true,
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
      original = generate_url_map(nav_data)
      RedirectNodes.create_homes_for_orphans(original, nav_data)
      assert_equal(
        [page_nav(
          'foo/', 'Foo',
          redirect: true,
          children: [
            page_nav(
              'bar/', 'Bar',
              redirect: true,
              children: [page_nav('baz/', 'Baz info')])
          ])
        ],
        nav_data)
    end

    def test_remove_stale_nav_entries_does_not_remove_generated_parent_nodes
      nav_data = [
        page_nav(
          'foo/', 'Foo',
          redirect: true,
          children: [
            page_nav(
              'bar/', 'Bar',
              redirect: true,
              children: [page_nav('baz/', 'Baz info')])
          ])
      ]
      original = generate_url_map(nav_data)
      updated = { '/foo/bar/baz/': true }
      refute_empty(
        NavigationMenu.remove_stale_nav_entries(nav_data, original, updated))
    end
  end
  # rubocop:enable MethodLength
  # rubocop:enable ClassLength
end
