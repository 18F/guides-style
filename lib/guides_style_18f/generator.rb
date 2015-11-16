# @author Mike Bland (michael.bland@gsa.gov)

require 'jekyll'
require 'us_web_design_standards'

module GuidesStyle18F
  class Generator < ::Jekyll::Generator
    def generate(site)
      Layouts.register site
      Assets.copy_to_site site
    end
  end
end
