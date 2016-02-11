# @author Mike Bland (michael.bland@gsa.gov)

require_relative './assets'
require_relative './breadcrumbs'
require_relative './layouts'

require 'jekyll'

module GuidesStyle18F
  class Generator < ::Jekyll::Generator
    def generate(site)
      Layouts.register site
      Assets.copy_to_site site
      breadcrumbs = Breadcrumbs.create(site)
      pages = site.collections['pages']
      docs = pages.nil? ? [] : pages.docs
      docs.each { |page| page.data['breadcrumbs'] = breadcrumbs[page.url] }
      flatten_url_namespace(docs) if site.config['flat_namespace']
    end

    private

    def flatten_url_namespace(docs)
      docs.each do |page|
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
