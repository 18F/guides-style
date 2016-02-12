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
      flat_to_orig = {}
      docs.each do |page|
        flattened_url = flat_url(page.url)
        (flat_to_orig[flattened_url] ||= []) << page.url
        page.data['permalink'] = flattened_url
        (page.data['breadcrumbs'] || []).each do |crumb|
          crumb['url'] = flat_url(crumb['url'])
        end
      end
      check_for_collisions(flat_to_orig)
    end

    def flat_url(url)
      File.join('', File.basename(url), '')
    end

    def check_for_collisions(flat_to_orig)
      collisions = flat_to_orig.map do |flattened, orig|
        [flattened, orig] if orig.size != 1
      end.compact

      return if collisions.empty?

      messages = collisions.map { |flat, orig| "#{flat}: #{orig.join(', ')}" }
      fail(StandardError, "collisions in flattened namespace between\n  " +
        messages.join("\n  "))
    end
  end
end
