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
      flatten_url_namespace(site) if site.config['flat_namespace']
    end

    def flatten_url_namespace(site)
      site.collections['pages'].docs.each do |page|
        page.data['permalink'] = flat_url(page.url)
        (page.data['breadcrumbs'] || []).each do |crumb|
        crumb['url'] = flat_url(crumb['url'])
        end
      end
    end

    def flat_url(url)
      File.join('', File.basename(url), '')
    end
  end
end
