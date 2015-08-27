# @author Mike Bland (michael.bland@gsa.gov)

require 'safe_yaml'

module GuidesStyle18F
  # Automatically updates the `navigation:` field in _config.yml.
  #
  # Does this by parsing the front matter from files in `pages/`. Preserves the
  # existing order of items in `navigation:`, but new items may need to be
  # reordered manually.
  def self.update_navigation_configuration(basedir)
    config_path = File.join basedir, '_config.yml'
    config_data = SafeYAML.load_file config_path, safe: true
    return unless config_data
    nav_data = update_navigation_data(
      (config_data['navigation'] || []), pages_front_matter_by_title(basedir))
    write_navigation_data_to_config_file config_path, nav_data
  end

  def self.pages_front_matter_by_title(basedir)
    Dir[File.join basedir, 'pages', '**', '*.md'].map do |f|
      front_matter = SafeYAML.load_file f, safe: true
      [front_matter['title'], front_matter]
    end.to_h
  end
  private_class_method :pages_front_matter_by_title

  def self.update_navigation_data(nav_data, pages_front_matter_by_title)
    nav_data_by_title = nav_data_by_title nav_data
    child_pages = []

    pages_front_matter_by_title.each do |title, front_matter|
      page_nav = page_nav title, front_matter
      title = title.downcase

      if front_matter.member? 'parent'
        child_pages << [title, front_matter, page_nav]
      elsif nav_data_by_title.member? title
        nav_data_by_title[title].merge! page_nav
      else
        nav_data << page_nav
      end
    end

    nav_data = remove_child_data nav_data, child_pages
    nav_data_by_title = nav_data_by_title nav_data
    child_pages.each do |title, front_matter, page_nav|
      add_child_to_parent title, front_matter, page_nav, nav_data_by_title
    end
    nav_data
  end
  private_class_method :update_navigation_data

  def self.nav_data_by_title(nav_data)
    nav_data.map { |nav| [nav['text'].downcase, nav] }.to_h
  end
  private_class_method :nav_data_by_title

  def self.page_nav(title, front_matter)
    { 'text' => title,
      'url' => "#{front_matter['permalink'].split('/').last}/",
      'internal' => true,
    }
  end
  private_class_method :page_nav

  def self.remove_child_data(nav_data, child_pages)
    titles = child_pages.map { |_, front_matter, _| front_matter['title'] }
    nav_data.reject { |nav| titles.include? nav['text'] }
  end
  private_class_method :remove_child_data

  def self.add_child_to_parent(title, child, page_nav, nav_data_by_title)
    parent = parent child, nav_data_by_title
    children = parent['children'] ||= []
    children_by_title = children.map { |i| [i['text'].downcase, i] }.to_h

    if children_by_title.member? title
      children_by_title[title].merge! page_nav
    else
      children << page_nav
    end
  end
  private_class_method :add_child_to_parent

  def self.parent(child, nav_data_by_title)
    parent = nav_data_by_title[child['parent'].downcase]
    if parent.nil?
      fail StandardError, 'Parent page not present in existing ' \
        "config: #{child['parent']}\nNeeded by: #{child['title']}"
    end
    parent
  end
  private_class_method :parent

  def self.write_navigation_data_to_config_file(config_path, nav_data)
    lines = []
    in_navigation = false
    open(config_path).each_line do |line|
      in_navigation = process_line line, lines, nav_data, in_navigation
    end
    File.write config_path, lines.join
  end
  private_class_method :write_navigation_data_to_config_file

  def self.process_line(line, lines, nav_data, in_navigation = false)
    if !in_navigation && line.start_with?('navigation:')
      inject_navigation_section line, lines, nav_data
      in_navigation = true
    elsif in_navigation
      in_navigation = maybe_skip_current_line line, lines
    else
      lines << line
    end
    in_navigation
  end
  private_class_method :process_line

  def self.inject_navigation_section(line, lines, nav_data)
    lines << line
    lines << nav_data.to_yaml["---\n".size..-1]
  end
  private_class_method :inject_navigation_section

  def self.maybe_skip_current_line(line, lines)
    return true if line.start_with?(' ') || line.start_with?('-')
    lines << line
    false
  end
  private_class_method :maybe_skip_current_line
end
