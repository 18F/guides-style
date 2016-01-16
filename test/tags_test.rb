require_relative '../lib/guides_style_18f/tags'

require 'liquid'
require 'minitest/autorun'

module GuidesStyle18F
  class ShouldExpandNavTagTest < ::Minitest::Test
    attr_reader :should_expand_nav, :context, :parent_item

    def setup
      tag_class = ::Liquid::Template.tags[ShouldExpandNavTag::NAME]
      @should_expand_nav = tag_class.parse(
        ShouldExpandNavTag::NAME, 'parent_item, nav_parent_url ', nil, nil)
      @context = ::Liquid::Context.new
      context['site'] = {}
      @parent_item = {}
      context.scopes.push(
        'parent_item' => parent_item, 'nav_parent_url' => '/foo/')
    end

    def test_is_child
      context['page'] = { 'url' => '/foo/bar/' }
      assert should_expand_nav.render(context)
    end

    def test_is_grandchild
      context['page'] = { 'url' => '/foo/bar/baz/' }
      assert should_expand_nav.render(context)
    end

    def test_is_not_a_child_or_grandchild
      context['page'] = { 'url' => '/bar/' }
      refute should_expand_nav.render(context)
    end

    def test_is_the_page_itself
      context['page'] = { 'url' => '/foo/' }
      refute should_expand_nav.render(context)
    end

    def test_expand_nav_site_default_is_true_so_unrelated_item_should_expand
      context['page'] = { 'url' => '/bar/' }
      context['site']['expand_nav'] = true
      assert should_expand_nav.render(context)
    end

    def test_expand_nav_site_default_is_false_but_child_item_should_expand
      context['page'] = { 'url' => '/foo/bar/' }
      context['site']['expand_nav'] = false
      assert should_expand_nav.render(context)
    end

    def test_expand_nav_site_default_is_true_but_item_default_is_false
      context['page'] = { 'url' => '/bar/baz' }
      context['site']['expand_nav'] = true
      parent_item['expand_nav'] = false
      refute should_expand_nav.render(context)
    end

    def test_expand_nav_site_default_is_false_but_item_default_is_true
      context['page'] = { 'url' => '/bar/baz' }
      context['site']['expand_nav'] = false
      parent_item['expand_nav'] = true
      assert should_expand_nav.render(context)
    end

    def test_expand_nav_site_default_is_nil_but_item_default_is_true
      context['page'] = { 'url' => '/bar/baz' }
      parent_item['expand_nav'] = true
      assert should_expand_nav.render(context)
    end
  end

  class PopLastUrlComponentTest < ::Minitest::Test
    attr_reader :pop_last_url_component, :context

    def setup
      tag_class = ::Liquid::Template.tags[PopLastUrlComponent::NAME]
      @pop_last_url_component = tag_class.parse(
        PopLastUrlComponent::NAME, ' parent_url ', nil, nil)
      @context = ::Liquid::Context.new
    end

    def test_pop_root
      context.scopes.push('parent_url' => '/')
      assert_equal('/', pop_last_url_component.render(context))
    end

    def test_pop_top_level_with_trailing_slash
      context.scopes.push('parent_url' => '/foo/')
      assert_equal('/', pop_last_url_component.render(context))
    end

    def test_pop_top_level_without_trailing_slash
      context.scopes.push('parent_url' => '/foo')
      assert_equal('/', pop_last_url_component.render(context))
    end

    def test_pop_second_level_with_trailing_slash
      context.scopes.push('parent_url' => '/foo/bar/')
      assert_equal('/foo/', pop_last_url_component.render(context))
    end

    def test_pop_second_level_without_trailing_slash
      context.scopes.push('parent_url' => '/foo/bar')
      assert_equal('/foo/', pop_last_url_component.render(context))
    end
  end
end
