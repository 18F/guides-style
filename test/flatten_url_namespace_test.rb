require_relative '../lib/guides_style_18f/generator'
require_relative './dummy_collection'
require_relative './dummy_page'
require_relative './dummy_site'

require 'jekyll/page'
require 'minitest/autorun'

module GuidesStyle18F
  # rubocop:disable ClassLength
  # rubocop:disable MethodLength
  class FlattenUrlNamespaceTest < ::Minitest::Test
    attr_accessor :site, :generator
    attr_accessor :home_page, :foo_page, :bar_page, :baz_page
    attr_accessor :quux_page, :xyzzy_page, :plugh_page, :all_docs

    def setup
      @site = DummySite.new
      @generator = Generator.new
      @home_page = DummyPage.new(site, '/')
      setup_pages
      @all_docs = [
        home_page,
        foo_page, bar_page, baz_page,
        quux_page, xyzzy_page, plugh_page
      ]
      setup_nav
    end

    def setup_pages
      @foo_page = DummyPage.new(site, '/foo/')
      @bar_page = DummyPage.new(site, '/foo/bar/')
      @baz_page = DummyPage.new(site, '/foo/baz/')
      @quux_page = DummyPage.new(site, '/quux/')
      @xyzzy_page = DummyPage.new(site, '/quux/xyzzy/')
      @plugh_page = DummyPage.new(site, '/quux/xyzzy/plugh/')
    end

    def setup_nav
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
    end

    def test_empty_data
      generator.generate(site)
      assert_nil(site.collections['docs'])
    end

    # rubocop:disable AbcSize
    def test_single_home_page
      site.collections['pages'] = DummyCollection.new([home_page])
      generator.generate(site)

      assert_equal('/', home_page.data['permalink'])
      assert_equal([{ 'url' => '/', 'text' => 'Introduction' }],
        home_page.data['breadcrumbs'])

      site.config['flat_namespace'] = true
      assert_equal('/', home_page.data['permalink'])
      assert_equal([{ 'url' => '/', 'text' => 'Introduction' }],
        home_page.data['breadcrumbs'])
    end

    def test_two_pages
      site.collections['pages'] = DummyCollection.new([home_page, foo_page])
      generator.generate(site)

      assert_equal('/', home_page.data['permalink'])
      assert_equal('/foo/', foo_page.data['permalink'])

      assert_equal([{ 'url' => '/', 'text' => 'Introduction' }],
        home_page.data['breadcrumbs'])
      assert_equal([{ 'url' => '/foo/', 'text' => 'Foo info' }],
        foo_page.data['breadcrumbs'])

      site.config['flat_namespace'] = true
      assert_equal('/', home_page.data['permalink'])
      assert_equal('/foo/', foo_page.data['permalink'])

      assert_equal([{ 'url' => '/', 'text' => 'Introduction' }],
        home_page.data['breadcrumbs'])
      assert_equal([{ 'url' => '/foo/', 'text' => 'Foo info' }],
        foo_page.data['breadcrumbs'])
    end

    def test_nested_namespace
      site.collections['pages'] = DummyCollection.new(all_docs)
      generator.generate(site)

      assert_equal('/', home_page.data['permalink'])
      assert_equal('/foo/', foo_page.data['permalink'])
      assert_equal('/foo/bar/', bar_page.data['permalink'])
      assert_equal('/foo/baz/', baz_page.data['permalink'])
      assert_equal('/quux/', quux_page.data['permalink'])
      assert_equal('/quux/xyzzy/', xyzzy_page.data['permalink'])
      assert_equal('/quux/xyzzy/plugh/', plugh_page.data['permalink'])

      assert_equal(
        [
          { 'url' => '/', 'text' => 'Introduction' },
        ],
        home_page.data['breadcrumbs'])
      assert_equal(
        [
          { 'url' => '/foo/', 'text' => 'Foo info' },
        ],
        foo_page.data['breadcrumbs'])
      assert_equal(
        [
          { 'url' => '/foo/', 'text' => 'Foo info' },
          { 'url' => '/foo/bar/', 'text' => 'Bar info' },
        ],
        bar_page.data['breadcrumbs'])
      assert_equal(
        [
          { 'url' => '/foo/', 'text' => 'Foo info' },
          { 'url' => '/foo/baz/', 'text' => 'Baz info' },
        ],
        baz_page.data['breadcrumbs'])
      assert_equal(
        [
          { 'url' => '/quux/', 'text' => 'Quux info' },
        ],
        quux_page.data['breadcrumbs'])
      assert_equal(
        [
          { 'url' => '/quux/', 'text' => 'Quux info' },
          { 'url' => '/quux/xyzzy/', 'text' => 'Xyzzy info' },
        ],
        xyzzy_page.data['breadcrumbs'])
      assert_equal(
        [
          { 'url' => '/quux/', 'text' => 'Quux info' },
          { 'url' => '/quux/xyzzy/', 'text' => 'Xyzzy info' },
          { 'url' => '/quux/xyzzy/plugh/', 'text' => 'Plugh info' },
        ],
        plugh_page.data['breadcrumbs'])
    end

    def test_flat_namespace
      site.config['flat_namespace'] = true
      site.collections['pages'] = DummyCollection.new(all_docs)
      generator.generate(site)

      assert_equal('/', home_page.data['permalink'])
      assert_equal('/foo/', foo_page.data['permalink'])
      assert_equal('/bar/', bar_page.data['permalink'])
      assert_equal('/baz/', baz_page.data['permalink'])
      assert_equal('/quux/', quux_page.data['permalink'])
      assert_equal('/xyzzy/', xyzzy_page.data['permalink'])
      assert_equal('/plugh/', plugh_page.data['permalink'])

      assert_equal(
        [
          { 'url' => '/', 'text' => 'Introduction' },
        ],
        home_page.data['breadcrumbs'])
      assert_equal(
        [
          { 'url' => '/foo/', 'text' => 'Foo info' },
        ],
        foo_page.data['breadcrumbs'])
      assert_equal(
        [
          { 'url' => '/foo/', 'text' => 'Foo info' },
          { 'url' => '/bar/', 'text' => 'Bar info' },
        ],
        bar_page.data['breadcrumbs'])
      assert_equal(
        [
          { 'url' => '/foo/', 'text' => 'Foo info' },
          { 'url' => '/baz/', 'text' => 'Baz info' },
        ],
        baz_page.data['breadcrumbs'])
      assert_equal(
        [
          { 'url' => '/quux/', 'text' => 'Quux info' },
        ],
        quux_page.data['breadcrumbs'])
      assert_equal(
        [
          { 'url' => '/quux/', 'text' => 'Quux info' },
          { 'url' => '/xyzzy/', 'text' => 'Xyzzy info' },
        ],
        xyzzy_page.data['breadcrumbs'])
      assert_equal(
        [
          { 'url' => '/quux/', 'text' => 'Quux info' },
          { 'url' => '/xyzzy/', 'text' => 'Xyzzy info' },
          { 'url' => '/plugh/', 'text' => 'Plugh info' },
        ],
        plugh_page.data['breadcrumbs'])
    end

    def test_raise_if_collisions_in_flat_namespace
      site.config['flat_namespace'] = true
      colliding_docs = [
        DummyPage.new(site, '/foo/'),
        DummyPage.new(site, '/foo/bar/'),
        DummyPage.new(site, '/foo/baz/'),
        DummyPage.new(site, '/bar/'),
        DummyPage.new(site, '/bar/baz/'),
      ]
      site.collections['pages'] = DummyCollection.new(colliding_docs)
      exception = assert_raises(StandardError) do
        generator.generate(site)
      end
      assert_equal("collisions in flattened namespace between\n" \
        "  /bar/: /foo/bar/, /bar/\n" \
        '  /baz/: /foo/baz/, /bar/baz/',
        exception.message)
    end
  end
  # rubocop:enable AbcSize
  # rubocop:enable MethodLength
  # rubocop:enable ClassLength
end
