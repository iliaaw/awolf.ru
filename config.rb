require 'haml'
require 'sass'
require 'rouge'

class Rouge::Formatters::HTML < Rouge::Formatter
  def stream_untableized(tokens, &b)
    yield "<pre class=#{@css_class.inspect}><code>"
    tokens.each do |tok, val|
      span(tok, val, &b)
    end
    yield '</code></pre>'
  end
end

set :css_dir, 'css'
set :js_dir, 'js'
set :images_dir, 'images'
set :markdown_engine, :redcarpet
set :markdown, :fenced_code_blocks => true, 
               :smartypants => true, 
               :strikethrough => true
set :haml, :ugly => true
Time.zone = 'Moscow'

page '/blog/feed.xml', :layout => false

activate :blog do |blog|
  blog.prefix = 'blog'
  blog.layout = 'post'

  blog.permalink = ':title.html'
  blog.taglink = 'tags/:tag.html'

  blog.tag_template = 'blog/tag.html'

  blog.paginate = true
  blog.per_page = 5
  blog.page_link = 'page:num'
end

activate :syntax

configure :build do
  activate :minify_css
  activate :minify_javascript
  activate :minify_html
end