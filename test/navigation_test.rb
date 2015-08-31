# @author Mike Bland (michael.bland@gsa.gov)

require_relative '../lib/guides_style_18f/navigation'

require 'fileutils'
require 'minitest/autorun'
require 'safe_yaml'
require 'stringio'

module GuidesStyle18F
  # rubocop:disable ClassLength
  class NavigationTest < ::Minitest::Test
    attr_reader :testdir, :config_path, :pages_dir

    TEST_DIR = File.dirname(__FILE__)
    NAV_DATA_PATH = File.join TEST_DIR, 'navigation_test_data.yml'
    NAV_YAML = File.read NAV_DATA_PATH
    NAV_DATA = SafeYAML.load NAV_YAML, safe: true
    TEST_PAGES_DIR = File.join TEST_DIR, 'pages'

    def setup
      @testdir = Dir.mktmpdir
      @config_path = File.join testdir, '_config.yml'
      @pages_dir = File.join testdir, 'pages'
      FileUtils.mkdir_p pages_dir
    end

    def teardown
      FileUtils.rm_rf testdir
    end

    def write_config(config_data)
      File.write config_path, config_data
    end

    def read_config
      File.read config_path
    end

    def copy_pages(pages)
      FileUtils.cp pages.map { |p| File.join TEST_PAGES_DIR, p }, pages_dir
    end

    def nav_array_to_hash(nav)
      (nav['navigation'] || []).map { |i| [i['text'], i] }.to_h
    end

    def assert_result_matches_expected_config
      # We can't do a straight string comparison, since the items may not be
      # in order relative to the original.
      result = read_config
      result_data = SafeYAML.load result, safe: true
      assert result.start_with? LEADING_COMMENT
      assert result.end_with? TRAILING_COMMENT
      assert_equal nav_array_to_hash(NAV_DATA), nav_array_to_hash(result_data)
    end

    def test_empty_config_no_pages
      write_config ''
      GuidesStyle18F.update_navigation_configuration @testdir
      assert_equal '', read_config
    end

    def test_empty_config_no_nav_data_no_pages
      write_config ''
      GuidesStyle18F.update_navigation_configuration @testdir
      assert_equal '', read_config
    end

    def test_config_with_nav_data_but_no_pages
      write_config NAV_YAML
      GuidesStyle18F.update_navigation_configuration @testdir
      assert_equal NAV_YAML, read_config
    end

    def test_all_pages_with_existing_data
      write_config NAV_YAML
      copy_pages ALL_PAGES
      GuidesStyle18F.update_navigation_configuration testdir
      assert_equal NAV_YAML, read_config
    end

    ALL_PAGES = %w(
      child-page.md config.md github.md images.md new-page.md posting.md)
    LEADING_COMMENT = '' \
      '# Comments before the navigation section should be preserved.'
    TRAILING_COMMENT = '' \
      "# Comments after the navigation section should also be preserved.\n"

    CONFIG_WITH_MISSING_PAGES = [
      LEADING_COMMENT,
      'navigation:',
      '- text: Introduction',
      '  url: index.html',
      '  internal: true',
      '- text: Adding a new page',
      '  url: adding-a-new-page/',
      '  internal: true',
      '  children:',
      '  - text: Making a child page',
      '    url: making-a-child-page/',
      '    internal: false',
      TRAILING_COMMENT,
    ].join "\n"

    def test_add_missing_pages
      write_config CONFIG_WITH_MISSING_PAGES
      copy_pages ALL_PAGES
      GuidesStyle18F.update_navigation_configuration testdir
      assert_result_matches_expected_config
    end

    CONFIG_MISSING_CHILD_PAGE = [
      LEADING_COMMENT,
      'navigation:',
      '- text: Introduction',
      '  url: index.html',
      '  internal: true',
      '- text: Adding a new page',
      '  url: adding-a-new-page/',
      '  internal: true',
      '- text: Adding images',
      '  url: adding-images/',
      '  internal: true',
      '- text: Updating the config file',
      '  url: updating-the-config-file/',
      '  internal: true',
      '- text: GitHub setup',
      '  url: github-setup/',
      '  internal: true',
      '- text: Post your guide',
      '  url: post-your-guide/',
      '  internal: true',
      TRAILING_COMMENT,
    ].join "\n"

    def test_add_missing_child_page
      write_config CONFIG_MISSING_CHILD_PAGE
      copy_pages ALL_PAGES
      GuidesStyle18F.update_navigation_configuration testdir
      assert_result_matches_expected_config
    end

    CONFIG_MISSING_PARENT_PAGE = [
      LEADING_COMMENT,
      'navigation:',
      '- text: Introduction',
      '  url: index.html',
      '  internal: true',
      '- text: Adding images',
      '  url: adding-images/',
      '  internal: true',
      '- text: Making a child page',
      '  url: making-a-child-page/',
      '  internal: true',
      '- text: Updating the config file',
      '  url: updating-the-config-file/',
      '  internal: true',
      '- text: GitHub setup',
      '  url: github-setup/',
      '  internal: true',
      '- text: Post your guide',
      '  url: post-your-guide/',
      '  internal: true',
      TRAILING_COMMENT,
    ].join "\n"

    # An entry for the child already exists, and we want to move it under a
    # parent page, under the presumption that the parent relationship was just
    # added.
    def test_add_missing_parent_page
      write_config CONFIG_MISSING_PARENT_PAGE
      copy_pages ALL_PAGES
      GuidesStyle18F.update_navigation_configuration testdir
      assert_result_matches_expected_config
    end

    def test_should_raise_if_parent_page_does_not_exist
      write_config CONFIG_MISSING_PARENT_PAGE
      copy_pages ALL_PAGES.reject { |page| page == 'new-page.md' }
      exception = assert_raises(StandardError) do
        GuidesStyle18F.update_navigation_configuration testdir
      end
      expected = 'Parent page not present in existing config: ' \
        '"Adding a new page" needed by: "Making a child page"'
      assert_equal expected, exception.message
    end

    CONFIG_CONTAINING_ONLY_INTRODUCTION = [
      LEADING_COMMENT,
      'navigation:',
      '- text: Introduction',
      '  url: index.html',
      '  internal: true',
      TRAILING_COMMENT,
    ].join "\n"

    def test_all_pages_starting_with_empty_data
      write_config CONFIG_CONTAINING_ONLY_INTRODUCTION
      copy_pages ALL_PAGES
      GuidesStyle18F.update_navigation_configuration testdir
      assert_result_matches_expected_config
    end

    MISSING_TITLE_AND_PERMALINK = <<MISSING_TITLE_AND_PERMALINK
---
other_property: other value
---
MISSING_TITLE_AND_PERMALINK

    MISSING_TITLE = <<MISSING_TITLE
---
permalink: /no-title/
---
MISSING_TITLE

    MISSING_LINK = <<MISSING_LINK
---
title: No permalink
---
MISSING_LINK

    NO_LEADING_SLASH = <<NO_LEADING_SLASH
---
title: No leading slash
permalink: no-leading-slash/
---
NO_LEADING_SLASH

    NO_TRAILING_SLASH = <<NO_TRAILING_SLASH
---
title: No trailing slash
permalink: /no-trailing-slash
---
NO_TRAILING_SLASH

    FILES_WITH_ERRORS = {
      'missing-front-matter.md' => 'no front matter brosef',
      'missing-title-and-permalink.md' => MISSING_TITLE_AND_PERMALINK,
      'missing-title.md' => MISSING_TITLE,
      'missing-link.md' => MISSING_LINK,
      'no-leading-slash.md' => NO_LEADING_SLASH,
      'no-trailing-slash.md' => NO_TRAILING_SLASH,
    }

    EXPECTED_ERRORS = <<EXPECTED_ERRORS
The following files have errors in their front matter:
  pages/missing-front-matter.md:
    no front matter defined
  pages/missing-link.md:
    no `permalink:` property
  pages/missing-title-and-permalink.md:
    no `title:` property
    no `permalink:` property
  pages/missing-title.md:
    no `title:` property
  pages/no-leading-slash.md:
    `permalink:` does not begin with '/'
  pages/no-trailing-slash.md:
    `permalink:` does not end with '/'
EXPECTED_ERRORS

    def write_page(filename, content)
      File.write File.join(pages_dir, filename), content
    end

    def test_detect_front_matter_errors
      FILES_WITH_ERRORS.each { |file, content| write_page file, content }
      errors = GuidesStyle18F::FrontMatter.validate_with_message_upon_error(
        GuidesStyle18F::FrontMatter.load(testdir))
      assert_equal EXPECTED_ERRORS, errors + "\n"
    end

    def test_show_error_message_and_exit_if_pages_front_matter_is_malformed
      orig_stderr, $stderr = $stderr, StringIO.new
      write_config "navigation:"
      FILES_WITH_ERRORS.each { |file, content| write_page file, content }
      exception = assert_raises(SystemExit) do
        GuidesStyle18F.update_navigation_configuration testdir
      end
      assert_equal 1, exception.status
      assert_equal EXPECTED_ERRORS + "_config.yml not updated\n", $stderr.string
    ensure
      $stderr = orig_stderr
    end
  end
  # rubocop:enable ClassLength
end
