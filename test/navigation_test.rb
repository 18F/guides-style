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
    TEST_PAGES_DIR = File.join TEST_DIR, '_pages'

    NAV_DATA_PATH = File.join(TEST_DIR, 'navigation_test_data.yml')
    NAV_YAML = File.read(NAV_DATA_PATH)
    NAV_DATA = SafeYAML.load(NAV_YAML, safe: true)

    COLLECTIONS_CONFIG = [
      'collections:',
      '  pages:',
      '    output: true',
      '    permalink: /:path/',
      '',
    ].join("\n")

    def setup
      @testdir = Dir.glob(Dir.mktmpdir).first
      @config_path = File.join testdir, '_config.yml'
      @pages_dir = File.join testdir, '_pages'
      FileUtils.mkdir_p pages_dir
    end

    def teardown
      FileUtils.rm_rf(testdir, secure: true)
    end

    def write_config(config_data, with_collections: true)
      prefix = with_collections ? "#{COLLECTIONS_CONFIG}\n" : ''
      File.write(config_path, "#{prefix}#{config_data}")
    end

    def read_config
      File.read config_path
    end

    def copy_pages(pages)
      pages.each do |page|
        parent_dir = File.dirname(page)
        full_orig_path = File.join(TEST_PAGES_DIR, page)
        target_dir = File.join(pages_dir, parent_dir)
        FileUtils.mkdir_p(target_dir)
        FileUtils.cp(full_orig_path, target_dir)
      end
    end

    def nav_array_to_hash(nav)
      (nav['navigation'] || []).map { |i| [i['text'], i] }.to_h
    end

    def assert_result_matches_expected_config(nav_data)
      # We can't do a straight string comparison, since the items may not be
      # in order relative to the original.
      result = read_config
      result_data = SafeYAML.load(result, safe: true)
      refute_equal(-1, result.index(LEADING_COMMENT),
        'Comment before `navigation:` section is missing')
      refute_equal(-1, result.index(TRAILING_COMMENT),
        'Comment after `navigation:` section is missing')
      assert_equal nav_array_to_hash(nav_data), nav_array_to_hash(result_data)
    end

    def test_empty_config_no_pages
      write_config('', with_collections: false)
      GuidesStyle18F.update_navigation_configuration @testdir
      assert_equal '', read_config
    end

    def test_empty_config_no_nav_data_no_pages
      write_config('', with_collections: false)
      GuidesStyle18F.update_navigation_configuration @testdir
      assert_equal '', read_config
    end

    def test_config_with_nav_data_but_no_pages
      write_config NAV_YAML
      GuidesStyle18F.update_navigation_configuration @testdir
      expected = [
        COLLECTIONS_CONFIG,
        LEADING_COMMENT,
        'navigation:',
        TRAILING_COMMENT,
      ].join("\n")
      assert_equal expected, read_config
    end

    ALL_PAGES = %w(
      add-a-new-page/make-a-child-page.md
      add-a-new-page.md
      add-images.md
      github-setup.md
      index.md
      post-your-guide.md
      update-the-config-file/understanding-baseurl.md
      update-the-config-file.md
    )

    def test_all_pages_with_existing_data
      write_config NAV_YAML
      copy_pages ALL_PAGES
      GuidesStyle18F.update_navigation_configuration testdir
      assert_equal "#{COLLECTIONS_CONFIG}\n#{NAV_YAML}", read_config
    end

    LEADING_COMMENT = '' \
      '# Comments before the navigation section should be preserved.'
    TRAILING_COMMENT = '' \
      "# Comments after the navigation section should also be preserved.\n"

    # We need to be careful not to modify the original NAV_DATA object when
    # sorting.
    def sorted_nav_data(nav_data)
      nav_data = {}.merge(nav_data)
      sorted = nav_data['navigation'].map { |i| i }.sort_by { |i| i['text'] }
      nav_data['navigation'] = sorted
      nav_data
    end

    def test_add_all_pages_from_scratch
      write_config([
        LEADING_COMMENT,
        'navigation:',
        TRAILING_COMMENT,
      ].join("\n"))
      copy_pages(ALL_PAGES)
      GuidesStyle18F.update_navigation_configuration testdir
      assert_result_matches_expected_config(sorted_nav_data(NAV_DATA))
    end

    def add_a_grandchild_page(nav_data, parent_text, child_text,
      grandchild_text, grandchild_url)
      parent = nav_data.detect { |nav| nav['text'] == parent_text }
      child = parent['children'].detect { |nav| nav['text'] == child_text }
      (child['children'] ||= []) << {
        'text' => grandchild_text, 'url' => grandchild_url, 'internal' => true
      }
    end

    def test_remove_stale_config_entries
      nav_data = SafeYAML.load(NAV_YAML, safe: true)
      add_a_grandchild_page(nav_data['navigation'], 'Add a new page',
        'Make a child page', 'Make a grandchild page', 'grandchild-page/')

      # We have to slice off the leading `---\n` of the YAML, and the trailing
      # newline.
      write_config([
        LEADING_COMMENT, nav_data.to_yaml[4..-2], TRAILING_COMMENT
      ].join("\n"))
      copy_pages ALL_PAGES
      GuidesStyle18F.update_navigation_configuration testdir
      assert_equal "#{COLLECTIONS_CONFIG}\n#{NAV_YAML}", read_config
    end

    def write_config_without_collection
      # Use the `pages/` dir instead of `_pages`. Set the default permalink
      # for all the pages so we don't need to manually update every page.
      @pages_dir = File.join(testdir, 'pages')
      FileUtils.mkdir_p pages_dir
      config = [
        'permalink: /:path/', LEADING_COMMENT, 'navigation:', TRAILING_COMMENT
      ].join("\n")
      write_config(config, with_collections: false)
    end

    def move_home_page_and_create_external_page
      # Pull the home page to the root to make sure it's included, and make a
      # new page outside of the `pages/` directory to make sure it isn't
      # included.
      copy_pages(ALL_PAGES)
      FileUtils.mv(File.join(pages_dir, 'index.md'), testdir)
      File.write(File.join(testdir, 'excluded.md'), [
        '---',
        'title: This page shouldn\'t appear in the navigation menu',
        '---',
      ].join("\n"))
    end

    def add_permalinks(pages)
      pages.each do |page|
        next if page == 'index.md'
        path = File.join(pages_dir, page)
        front_matter = SafeYAML.load_file(path, safe: true)
        front_matter['permalink'] = "/#{page.sub(/\.md$/, '')}/"
        File.write(path, "#{front_matter.to_yaml}\n---")
      end
    end

    CONFIG_WITH_EXTERNAL_PAGE = [
      COLLECTIONS_CONFIG,
      LEADING_COMMENT,
      'navigation:',
      '- text: Link to the 18F/guides-style repo',
      '  url: https://github.com/18F/guides-style',
      TRAILING_COMMENT,
    ].join("\n")

    def test_do_not_remove_external_page_entries
      write_config(CONFIG_WITH_EXTERNAL_PAGE)
      copy_pages(ALL_PAGES)
      GuidesStyle18F.update_navigation_configuration testdir
      expected_data = sorted_nav_data(NAV_DATA)
      expected_data['navigation'].unshift(
        'text' => 'Link to the 18F/guides-style repo',
        'url' => 'https://github.com/18F/guides-style',
      )
      assert_result_matches_expected_config(expected_data)
    end

    CONFIG_WITH_MISSING_PAGES = [
      COLLECTIONS_CONFIG,
      LEADING_COMMENT,
      'navigation:',
      '- text: Introduction',
      '  internal: true',
      '- text: Add a new page',
      '  url: add-a-new-page/',
      '  internal: true',
      '  children:',
      '  - text: Make a child page',
      '    url: make-a-child-page/',
      '    internal: true',
      TRAILING_COMMENT,
    ].join "\n"

    def test_add_missing_pages
      write_config CONFIG_WITH_MISSING_PAGES
      copy_pages ALL_PAGES
      GuidesStyle18F.update_navigation_configuration testdir
      assert_result_matches_expected_config(NAV_DATA)
    end

    CONFIG_MISSING_CHILD_PAGES = [
      COLLECTIONS_CONFIG,
      LEADING_COMMENT,
      'navigation:',
      '- text: Introduction',
      '  internal: true',
      '- text: Add a new page',
      '  url: add-a-new-page/',
      '  internal: true',
      '- text: Add images',
      '  url: add-images/',
      '  internal: true',
      '- text: Update the config file',
      '  url: update-the-config-file/',
      '  internal: true',
      '- text: GitHub setup',
      '  url: github-setup/',
      '  internal: true',
      '- text: Post your guide',
      '  url: post-your-guide/',
      '  internal: true',
      TRAILING_COMMENT,
    ].join "\n"

    def test_add_missing_child_pages
      write_config CONFIG_MISSING_CHILD_PAGES
      copy_pages ALL_PAGES
      GuidesStyle18F.update_navigation_configuration testdir
      assert_result_matches_expected_config(NAV_DATA)
    end

    CONFIG_MISSING_PARENT_PAGE = [
      COLLECTIONS_CONFIG,
      LEADING_COMMENT,
      'navigation:',
      '- text: Introduction',
      '  internal: true',
      '- text: Add images',
      '  url: add-images/',
      '  internal: true',
      '- text: Make a child page',
      '  url: make-a-child-page/',
      '  internal: true',
      '- text: Update the config file',
      '  url: update-the-config-file/',
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
      assert_result_matches_expected_config(NAV_DATA)
    end

    def test_should_raise_if_parent_page_does_not_exist
      write_config CONFIG_MISSING_PARENT_PAGE
      copy_pages ALL_PAGES.reject { |page| page == 'add-a-new-page.md' }
      exception = assert_raises(StandardError) do
        GuidesStyle18F.update_navigation_configuration testdir
      end
      expected = "Parent pages missing for the following:\n  " \
        '/add-a-new-page/make-a-child-page/'
      assert_equal expected, exception.message
    end

    CONFIG_CONTAINING_ONLY_INTRODUCTION = [
      COLLECTIONS_CONFIG,
      LEADING_COMMENT,
      'navigation:',
      '- text: Introduction',
      '  internal: true',
      TRAILING_COMMENT,
    ].join "\n"

    def test_all_pages_starting_with_empty_data
      write_config CONFIG_CONTAINING_ONLY_INTRODUCTION
      copy_pages ALL_PAGES
      GuidesStyle18F.update_navigation_configuration testdir
      assert_result_matches_expected_config(NAV_DATA)
    end

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
      'no-leading-slash.md' => NO_LEADING_SLASH,
      'no-trailing-slash.md' => NO_TRAILING_SLASH,
    }

    EXPECTED_ERRORS = {
      "_pages/missing-front-matter.md" => ["no front matter defined"],
      "_pages/no-leading-slash.md" => ["`permalink:` does not begin with '/'"],
      "_pages/no-trailing-slash.md" => ["`permalink:` does not end with '/'"]
    }

    def write_page(filename, content)
      File.write File.join(pages_dir, filename), content
    end

    def test_detect_front_matter_errors
      write_config NAV_YAML
      FILES_WITH_ERRORS.each { |file, content| write_page file, content }
      front_matter = GuidesStyle18F::FrontMatter.load(testdir)
      errors = GuidesStyle18F::FrontMatter.validate(front_matter)
      assert_equal(EXPECTED_ERRORS, errors)
    end

    def test_ignore_static_files
      write_config NAV_YAML
      write_page('image.png', '')
      errors = GuidesStyle18F::FrontMatter.validate_with_message_upon_error(
        GuidesStyle18F::FrontMatter.load(testdir))
      assert_nil(errors)
    end

    WITH_NAVTITLE = <<WITH_NAVTITLE
---
title: Some egregiously, pretentiously, criminally long title
navtitle: Hello!
---
WITH_NAVTITLE

    def test_use_navtitle_if_present
      write_config NAV_YAML
      write_page('navtitle.md', WITH_NAVTITLE)
      GuidesStyle18F.update_navigation_configuration testdir
      expected = [{
        'text' => 'Hello!', 'url' => 'navtitle/', 'internal' => true
      }]
      result = SafeYAML.load(read_config, safe: true)
      assert_equal(expected, result['navigation'])
    end

    def capture_stderr
      orig_stderr = $stderr
      $stderr = StringIO.new
      yield
    ensure
      $stderr = orig_stderr
    end

    def test_show_error_message_and_exit_if_pages_front_matter_is_malformed
      capture_stderr do
        write_config "#{COLLECTIONS_CONFIG}\nnavigation:"
        FILES_WITH_ERRORS.each { |file, content| write_page file, content }
        exception = assert_raises(SystemExit) do
          GuidesStyle18F.update_navigation_configuration testdir
        end
        assert_equal 1, exception.status
        assert_includes($stderr.string, "_config.yml not updated")
      end
    end
  end
  # rubocop:enable ClassLength
end
