# @author Mike Bland (michael.bland@gsa.gov)

require 'jekyll'

module GuidesStyle18F
  class Generator < ::Jekyll::Generator
    def generate(site)
      breadcrumbs = Breadcrumbs.create(site)
      Layouts.register site
      Assets.copy_to_site site
      site.collections['pages'].docs.each do |page|
        page.data['breadcrumbs'] = breadcrumbs[page.url]
      end
    end
  end
end
