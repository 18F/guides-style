## [`guides_style_18f`](https://rubygems.org/gems/guides_style_18f): 18F Guides style gem

[![Build Status](https://travis-ci.org/18F/guides-style.svg?branch=master)](https://travis-ci.org/18F/guides-style)

Provides consistent style elements for [Jekyll](https://jekyllrb.com/)-based
web sites based on the
[18F Guides Template](https://pages.18f.gov/guides-template/).  The 18F Guides
theme is based on [DOCter](https://github.com/cfpb/docter/) from
[CFPB](http://cfpb.github.io/).

### Usage

In your [`Gemfile`](http://bundler.io/gemfile.html), include the following:

```ruby
group :jekyll_plugins do
  gem 'guides_style_18f'
end
```

Add an `assets/css/styles.scss` file that contains at least the following:

```scss
---
---

@import "guides_style_18f";
```

Then in your [`_config.yml` file](https://jekyllrb.com/docs/configuration/),
add the following (you may need to remove any `layout:`
[front matter](https://jekyllrb.com/docs/frontmatter/) from existing pages for
this to take effect):

```yaml
defaults:
  -
    scope:
      path: ""
    values:
      layout: "guides_style_18f_default"
```

Build the site per usual, and observe the results.

### Additional features

Here are some other features that can be enabled via `_config.yml`:

```yaml
# To use the shared 18F Guides Teamplate assets when deploying to
# pages.18f.gov, to avoid having to rebuild the site for minor style and
# script updates:
asset_root: /guides-template

# This adds the "back to" breadcrumb link under the page title:
back_link:
  url: "https://pages.18f.gov/guides/"
  text: Read more 18F Guides

# If you use Analytics, add your code here:
google_analytics_ua: UA-????????-??

# If you want all of the navigation bar entries expanded by default, add this
# property and it to true:
expand_nav: true
```

### Additional scripts and styles

If you'd like to add additional scripts or styles to every page on the site,
you can add `styles:` and `scripts:` lists to `_config.yml`. To add them to a
particular page, add these lists to the page's front matter.

### Alternate navigation bar titles

If you want a page to have a different title in the navigation bar than that
of the page itself, add a `navtitle:` property to the page's front matter:

```md
---
title: Since brevity is the soul of wit, I'll be brief.
navtitle: Polonius's advice
---
```

### Selectively expanding navigation bar items

If you wish to expand or contract specific navigation bar items, add the
`expand_nav:` property to those items in the `navigation:` list in
`_config.yml`. For example, the `Update the config file` entry will expand
since the default `expand_nav` property is `true`, but `Add a new page` will
remain collapsed:

```yaml
expand_nav: true

navigation:
- text: Introduction
  internal: true
- text: Add a new page
  url: add-a-new-page/
  internal: true
  expand_nav: false
  children:
  - text: Make a child page
    url: make-a-child-page/
    internal: true
- text: Update the config file
  url: update-the-config-file/
  internal: true
  children:
  - text: Understanding the `baseurl:` property
    url: understanding-baseurl/
    internal: true
```

### Search

There are two options for search.

#### jekyll_pages_api_search

Pros:

* Generates a search index locally, which has the advantage of being self-contained. This means you can easily test search locally, on a staging site, etc.
* Search results are shown in your site's layout

Cons:

* Slows down your build

Usage: see [the instructions](https://github.com/18F/jekyll_pages_api_search#installation).

#### search.gov

Pros:

* A hosted service, so your site has fewer moving parts.
* A more full-featured search engine
* Search results show a preview of the text on the page, with highlighted term(s)
* Provides analytics

Cons:

* You need to register your site
* Can't test search results locally

Usage:

1. Register your site at [search.gov](https://search.gov/).
1. Add the following to your `_config.yml`:

    ```yaml
    search_gov_handle: <your Site Handle from the search.gov Settings page>
    ```

### Development

First, choose a Jekyll site you'd like to use to view the impact of your
updates and clone its repository; then clone this repository into the same
parent directory. For example, to use the 18F Guides Template:

```shell
$ git clone git@github.com:18F/guides-template.git
$ git clone git@github.com:18F/guides-style.git
```

In the `Gemfile` of the Jekyll site's repository, include the following:

```ruby
group :jekyll_plugins do
  gem 'guides_style_18f', :path => '../guides-style'
end
```

You can find the different style assets and templates within subdirectories of
the `assets` and `lib/guides_style_18f` directories of this repository. Edit
those, then rebuild the Jekyll site as usual to see the results.

### Public domain

This project is in the worldwide [public domain](LICENSE.md). As stated in [CONTRIBUTING](CONTRIBUTING.md):

> This project is in the public domain within the United States, and copyright and related rights in the work worldwide are waived through the [CC0 1.0 Universal public domain dedication](https://creativecommons.org/publicdomain/zero/1.0/).
>
> All contributions to this project will be released under the CC0
>dedication. By submitting a pull request, you are agreeing to comply
>with this waiver of copyright interest.
