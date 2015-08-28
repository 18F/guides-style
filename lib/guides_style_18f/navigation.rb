# @author Mike Bland (michael.bland@gsa.gov)

require 'safe_yaml'

module GuidesStyle18F
  module FrontMatter
    def self.load(basedir)
      Dir[File.join basedir, 'pages', '**', '*.md'].map do |f|
        [f[basedir.size + 1..-1], SafeYAML.load_file(f, safe: true)]
      end.to_h
    end

    def self.validate_with_message_upon_error(front_matter)
      files_with_errors = validate front_matter
      return if files_with_errors.empty?
      message = ['The following files have errors in their front matter:']
      files_with_errors.each do |file, errors|
        message << "  #{file}:"
        message.concat errors.map { |error| "    #{error}" }
      end
      message.join "\n" unless message.size == 1
    end

    def self.validate(front_matter)
      front_matter.map do |file, data|
        next [file, ['no front matter defined']] unless data.instance_of? Hash
        errors = missing_property_errors(data) + permalink_errors(data)
        [file, errors] unless errors.empty?
      end.compact.to_h
    end

    def self.missing_property_errors(data)
      properties = %w(title permalink)
      properties.map { |p| "no `#{p}:` property" unless data[p] }.compact
    end
    private_class_method :missing_property_errors

    def self.permalink_errors(data)
      pl = data['permalink']
      return [] if pl.nil?
      errors = []
      errors << "`permalink:` does not begin with '/'" unless pl.start_with? '/'
      errors << "`permalink:` does not end with '/'" unless pl.end_with? '/'
      errors
    end
    private_class_method :permalink_errors
  end

  # Automatically updates the `navigation:` field in _config.yml.
  #
  # Does this by parsing the front matter from files in `pages/`. Preserves the
  # existing order of items in `navigation:`, but new items may need to be
  # reordered manually.
  def self.update_navigation_configuration(basedir)
    config_path = File.join basedir, '_config.yml'
    config_data = SafeYAML.load_file config_path, safe: true
    return unless config_data
    nav_data = config_data['navigation'] || []
    nav_data = update_navigation_data nav_data, basedir
    write_navigation_data_to_config_file config_path, nav_data
  end

  def self.update_navigation_data(nav_data, basedir)
    pages_data = pages_front_matter basedir
    children = pages_data['children'].map { |child| child['title'].downcase }
    nav_data.reject! { |nav| children.include? nav['text'].downcase }
    update_parent_nav_data nav_data, pages_data['parents']
    add_children_to_parents nav_data, pages_data['children']
  end
  private_class_method :update_navigation_data

  def self.pages_front_matter(basedir)
    front_matter = FrontMatter.load basedir
    errors = FrontMatter.validate_with_message_upon_error front_matter
    abort errors + "\n_config.yml not updated" if errors
    pages_data = front_matter.values.group_by do |fm|
      fm['parent'].nil? ? 'parents' : 'children'
    end
    %w(parents children).each { |category| pages_data[category] ||= [] }
    pages_data
  end
  private_class_method :pages_front_matter

  def self.update_parent_nav_data(nav_data, parents)
    nav_by_title = nav_data_by_title nav_data
    parents.each do |page|
      page_nav = page_nav page
      title = page_nav['text'].downcase
      if nav_by_title.member? title
        nav_by_title[title].merge! page_nav
      else
        nav_data << page_nav
      end
    end
  end
  private_class_method :update_parent_nav_data

  def self.nav_data_by_title(nav_data)
    nav_data.map { |nav| [nav['text'].downcase, nav] }.to_h
  end
  private_class_method :nav_data_by_title

  def self.page_nav(front_matter)
    { 'text' => front_matter['title'],
      'url' => "#{front_matter['permalink'].split('/').last}/",
      'internal' => true,
    }
  end
  private_class_method :page_nav

  def self.add_children_to_parents(nav_data, children)
    parents_by_title = nav_data_by_title nav_data
    children.each { |child| add_child_to_parent child, parents_by_title }
    nav_data
  end
  private_class_method :add_children_to_parents

  def self.add_child_to_parent(child, parents_by_title)
    child_nav_data = page_nav child
    title = child_nav_data['text'].downcase
    parent = parent child, parents_by_title
    children = parent['children'] ||= []
    children_by_title = children.map { |c| [c['text'].downcase, c] }.to_h

    if children_by_title.member? title
      children_by_title[title].merge! child_nav_data
    else
      children << child_nav_data
    end
  end
  private_class_method :add_child_to_parent

  def self.parent(child, parents_by_title)
    parent = parents_by_title[child['parent'].downcase]
    return parent unless parent.nil?
    fail StandardError, 'Parent page not present in existing ' \
      "config: \"#{child['parent']}\" needed by: \"#{child['title']}\""
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
      lines << line << nav_data.to_yaml["---\n".size..-1]
      in_navigation = true
    elsif in_navigation
      in_navigation = line.start_with?(' ') || line.start_with?('-')
      lines << line unless in_navigation
    else
      lines << line
    end
    in_navigation
  end
  private_class_method :process_line
end
