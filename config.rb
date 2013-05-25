require 'haml'
require 'sass'

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
  blog.year_link = ':year.html'
  blog.month_link = ':year/:month.html'
  blog.day_link = ':year/:month/:day.html'

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