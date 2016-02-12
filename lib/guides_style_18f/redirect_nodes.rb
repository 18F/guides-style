module GuidesStyle18F
  class RedirectNodes
    # Params:
    #   original: Mapping from original document URL to "nav item" objects,
    #     i.e. { 'text' => '...', 'url' => '...', 'internal' => true }
    #   nav_data: Array of nav item objects contained in `original` after
    #     applying updates, possibly containing "orphan" items marked with an
    #     `:orphan_url` property
    #
    # Returns:
    #   nav_data with orphans properly nested within automatically-generated
    #     parent nodes marked with `'redirect' => true`
    def self.create_homes_for_orphans(original, nav_data)
      orphans = nav_data.select { |nav| nav[:orphan_url] }
      orphans.each { |nav| create_home_for_orphan(nav, nav_data, original) }
      nav_data.reject! { |nav| nav[:orphan_url] }
      prune_childless_parents(nav_data)
    end

    def self.create_home_for_orphan(nav, nav_data, original)
      parents = nav[:orphan_url].split('/')[1..-1]
      nav['url'] = parents.pop + '/'
      child_url = '/'
      immediate_parent = parents.reduce(nil) do |parent, child|
        child_url = child_url + child + '/'
        link_parent_to_child(nav_data, child_url, parent, child, original)
      end
      nav_copy = {}.merge(nav)
      nav_copy.delete(:orphan_url)
      (immediate_parent['children'] ||= []) << nav_copy
    end

    def self.link_parent_to_child(nav_data, child_url, parent, child, original)
      child_nav = original[child_url]
      if child_nav.nil?
        child_nav = redirect_node(child)
        original[child_url] = child_nav
        (parent.nil? ? nav_data : (parent['children'] ||= [])) << child_nav
      end
      child_nav
    end

    def self.redirect_node(parent_slug)
      { 'text' => parent_slug.split('-').join(' ').capitalize,
        'url' => parent_slug + '/',
        'internal' => true,
        'redirect' => true,
      }
    end

    def self.prune_childless_parents(nav_data)
      (nav_data || []).reject! do |nav|
        children = (nav['children'] || [])
        prune_childless_parents(children)
        nav['redirect'] && children.empty?
      end
    end
  end
end
