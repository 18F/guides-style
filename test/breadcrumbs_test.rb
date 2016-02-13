require_relative '../lib/guides_style_18f/breadcrumbs'

require 'minitest/autorun'

module GuidesStyle18F
  class DummySite
    attr_accessor :config

    def initialize
      @config = {}
    end
  end

  class BreadcrumbsTest < ::Minitest::Test
    attr_accessor :site

    def setup
      @site = DummySite.new
    end

    def test_empty_data
      assert_empty(Breadcrumbs.create_breadcrumbs(site))
    end

    def test_single_nav_item_for_home_page_without_url_member
      site.config['navigation'] = [{ 'text' => 'Introduction' }]
      expected = { '/' => [{ 'url' => '/', 'text' => 'Introduction' }] }
      assert_equal(expected, Breadcrumbs.create_breadcrumbs(site))
    end

    def test_multiple_nav_items
      site.config['navigation'] = [
        { 'text' => 'Introduction' },
        { 'url' => 'foo/', 'text' => 'Foo info' },
      ]
      expected = {
        '/' => [{ 'url' => '/', 'text' => 'Introduction' }],
        '/foo/' => [{ 'url' => '/foo/', 'text' => 'Foo info' }],
      }
      assert_equal(expected, Breadcrumbs.create_breadcrumbs(site))
    end

    # rubocop:disable MethodLength
    def test_nav_items_with_children
      site.config['navigation'] = [
        { 'text' => 'Introduction' },
        { 'url' => 'foo/',
          'text' => 'Foo info',
          'children' => [
            { 'url' => 'bar/', 'text' => 'Bar info' },
            { 'url' => 'baz/', 'text' => 'Baz info' },
          ],
        },
        { 'url' => 'quux/',
          'text' => 'Quux info',
          'children' => [
            { 'url' => 'xyzzy/',
              'text' => 'Xyzzy info',
              'children' => [
                { 'url' => 'plugh/', 'text' => 'Plugh info' },
              ],
            },
          ],
        },
      ]
      expected = {
        '/' => [{ 'url' => '/', 'text' => 'Introduction' }],
        '/foo/' => [{ 'url' => '/foo/', 'text' => 'Foo info' }],
        '/foo/bar/' => [
          { 'url' => '/foo/', 'text' => 'Foo info' },
          { 'url' => '/foo/bar/', 'text' => 'Bar info' },
        ],
        '/foo/baz/' => [
          { 'url' => '/foo/', 'text' => 'Foo info' },
          { 'url' => '/foo/baz/', 'text' => 'Baz info' },
        ],
        '/quux/' => [{ 'url' => '/quux/', 'text' => 'Quux info' }],
        '/quux/xyzzy/' => [
          { 'url' => '/quux/', 'text' => 'Quux info' },
          { 'url' => '/quux/xyzzy/', 'text' => 'Xyzzy info' },
        ],
        '/quux/xyzzy/plugh/' => [
          { 'url' => '/quux/', 'text' => 'Quux info' },
          { 'url' => '/quux/xyzzy/', 'text' => 'Xyzzy info' },
          { 'url' => '/quux/xyzzy/plugh/', 'text' => 'Plugh info' },
        ],
      }
      assert_equal(expected, Breadcrumbs.create_breadcrumbs(site))
    end
    # rubocop:enable MethodLength
  end
end
