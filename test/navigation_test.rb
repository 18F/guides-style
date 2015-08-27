# @author Mike Bland (michael.bland@gsa.gov)

require_relative '../lib/guides_style_18f/navigation'

require 'fileutils'
require 'minitest/autorun'
require 'safe_yaml'

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
  end
  # rubocop:enable ClassLength
end
