require 'jekyll/tags/include'
require 'liquid'

module GuidesStyle18F
  class ShouldExpandNavTag < ::Liquid::Tag
    NAME = 'guides_style_18f_should_expand_nav'
    ::Liquid::Template.register_tag(NAME, self)

    attr_reader :reference

    def initialize(_tag_name, markup, _)
      @reference = markup.strip
    end

    def render(context)
      scope = context.scopes.detect { |s| s.member?(reference) }
      parent_url = scope[reference]
      page_url = context['page']['url']
      page_url != parent_url && page_url.start_with?(parent_url)
    end
  end

  class PopLastUrlComponent < ::Liquid::Tag
    NAME = 'guides_style_18f_pop_last_url_component'
    ::Liquid::Template.register_tag(NAME, self)

    attr_reader :reference

    def initialize(_tag_name, markup, _)
      @reference = markup.strip
    end

    def render(context)
      scope = context.scopes.detect { |s| s.member?(reference) }
      parent_url = scope[reference]
      result = File.dirname(parent_url)
      result == '/' ? result : "#{result}/"
    end
  end
end
