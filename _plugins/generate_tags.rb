# Jekyll tag page generator.
# http://recursive-design.com/projects/Jekyll-plugins/
#
# Version: 0.1.3 (201101061053)
#
# Copyright (c) 2010 Dave Perrett, http://recursive-design.com/
# Licensed under the MIT license (http://www.opensource.org/licenses/mit-license.php)
#
# A generator that creates tag pages for Jekyll sites. 
#
# To use it, simply drop this script into the _plugins directory of your Jekyll site. You should 
# also create a file called 'tag_index.html' in the _layouts directory of your Jekyll site 
# with the following contents (note: you should remove the leading '# ' characters):
#
# ================================== COPY BELOW THIS LINE ==================================
# ---
# layout: default
# ---
# 
# <h1 class="tag">{{ page.title }}</h1>
# <ul class="posts">
# {% for post in site.tags[page.tag] %}
#     <div>{{ post.date | date_to_html_string }}</div>
#     <h2><a href="{{ post.url }}">{{ post.title }}</a></h2>
#     <div class="tags">Filed under {{ post.tags | tag_links }}</div>
# {% endfor %}
# </ul>
# ================================== COPY ABOVE THIS LINE ==================================
# 
# You can alter the _layout_ setting if you wish to use an alternate layout, and obviously you
# can change the HTML above as you see fit. 
#
# When you compile your Jekyll site, this plugin will loop through the list of tags in your 
# site, and use the layout above to generate a page for each one with a list of links to the 
# individual posts.
#
# Included filters :
# - tag_links:      Outputs the list of tags as comma-separated <a> links.
# - date_to_html_string: Outputs the post.date as formatted html, with hooks for CSS styling.
#
# Available _config.yml settings :
# - tag_dir:          The subfolder to build tag pages in (default is 'tags').
# - tag_title_prefix: The string used before the tag name in the page title (default is 
#                          'Tag: ').
module Jekyll
  
  # The TagIndex class creates a single tag page for the specified tag.
  class TagIndex < Page
    
    # Initializes a new TagIndex.
    #
    #  +base+         is the String path to the <source>.
    #  +tag_dir+ is the String path between <source> and the tag folder.
    #  +tag+     is the tag currently being processed.
    def initialize(site, base, tag_dir, tag)
      @site = site
      @base = base
      @dir  = tag_dir
      @name = 'index.html'
      self.process(@name)
      # Read the YAML data from the layout page.
      self.read_yaml(File.join(base, '_layouts'), 'tag_index.html')
      self.data['tag']    = tag
      # Set the title for this page.
      title_prefix             = site.config['tag_title_prefix'] || 'Everything tagged with #'
      self.data['title']       = "#{title_prefix}#{tag}"
      # Set the meta-description for this page.
      meta_description_prefix  = site.config['tag_meta_description_prefix'] || 'Tag: '
      self.data['description'] = "#{meta_description_prefix}#{tag}"
    end
    
  end
  
  
  # The Site class is a built-in Jekyll class with access to global site config information.
  class Site

    require 'active_support/all'

    # Creates an instance of TagIndex for each tag page, renders it, and 
    # writes the output to a file.
    #
    #  +tag_dir+ is the String path to the tag folder.
    #  +tag+     is the tag currently being processed.
    def write_tag_index(tag_dir, tag)
      index = TagIndex.new(self, self.source, tag_dir, tag)
      index.render(self.layouts, site_payload)
      index.write(self.dest)
      # Record the fact that this page has been added, otherwise Site::cleanup will remove it.
      self.pages << index
    end
    
    # Loops through the list of tag pages and processes each one.
    def write_tag_indexes
      if self.layouts.key? 'tag_index'
        dir = self.config['tag_dir'] || '/tags'
        
        self.tags.keys.each do |tag|
          item = tag['name'] || tag
          self.write_tag_index(File.join(dir, item.parameterize), item)
        end
        
      # Throw an exception if the layout couldn't be found.
      else
        throw "No 'tag_index' layout found."
      end
    end
 
  end
  
  
  # Jekyll hook - the generate method is called by Jekyll, and generates all of the tag pages.
  class GenerateTags < Generator
    safe true
    priority :low

    def generate(site)
      site.write_tag_indexes
    end

  end
  
  
  # Adds some extra filters used during the tag creation process.
  module Filters
    
    require 'uri'
    require 'active_support/all'
    
    # Outputs a list of tags as comma-separated <a> links. This is used
    # to output the tag list for each post on a tag page.
    #
    #  +tags+ is the list of tags to format.
    #
    # Returns string
    def tag_links(tags)
      tags.sort!.map do |item|
        tag = item['name'] || item
        ' <a href="/tags/' + tag.parameterize + '/" class="tag-link">#'+tag+'</a> '
      end
    end

    def popular_tags(items)
    
      tags = items.sort {|a,b| b[1].size <=> a[1].size }
      
      html = String.new
      
      html << "<ul>"
      
      tags[0..39].each do | key, value |
        tag = key['name'] || key
        html << "<li><a href=\"/tags/#{tag.parameterize}\" title=\"Pages tagged #{tag}\">#{tag}</a></li>"
      end
      
      html  << "</ul>"
    
    end
	
	  def tag_cloud(tags)
	
      maxFontSize = 300
      minFontSize = 80
      
      html = String.new	
      
      tags = tags.sort {|a,b| a[0].downcase <=> b[0].downcase }
      biggest_item = tags.max { |x,y| x[1].size <=> y[1].size }
      smallest_item = tags.min { |x,y| x[1].size <=> y[1].size }
      
      tags.each do | key, val |    
        tag = key['name'] || key
        weight = (Math.log(val.length)-Math.log(smallest_item[1].size))/(Math.log(biggest_item[1].size)-Math.log(smallest_item[1].size));
        font_size = minFontSize + ((maxFontSize-minFontSize) * weight).round;
        html << '<a href="/tags/' + tag.paramterize + '/" title="Pages tagged ' + tag + '" style="font-size: ' + font_size.to_s + '%" rel=\"tag\">' + tag + '</a> '
      end
      
      html
    
    end

  end
  
end