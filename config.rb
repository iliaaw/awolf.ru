require 'haml'

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
  blog.per_page = 2
  blog.page_link = 'page:num'
end

page '/blog/index.html', :layout => 'blog'
page '/blog/tags/*', :layout => 'blog'
page '/feed.xml', :layout => false

set :css_dir, 'css'
set :js_dir, 'js'
set :images_dir, 'images'

configure :build do
  activate :minify_css
  activate :minify_javascript
end
