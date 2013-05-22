require 'haml'

set :css_dir, 'css'
set :js_dir, 'js'
set :images_dir, 'images'

configure :build do
  activate :minify_css
  activate :minify_javascript
end
