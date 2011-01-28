puts "Installing jQuery"

get "http://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js",  "public/javascripts/jquery.js"
get "https://github.com/rails/jquery-ujs/raw/master/src/rails.js", "public/javascripts/rails.js"

# JQuery UI
get "http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.9/jquery-ui.min.js",  "public/javascripts/jquery-ui.js"

# include rails.js with javascript defaults
gsub_file 'config/application.rb', 'config.action_view.javascript_expansions[:defaults] = %w()', "config.action_view.javascript_expansions = { :defaults => ['rails'] }"

defer "layout" do
  inject_into_file 'app/views/layouts/application.html.erb', %q(

    <!-- Grab Google CDN's jQuery. fall back to local if necessary -->
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js"></script>
    <script>!window.jQuery && document.write(unescape('%3Cscript src="/javascripts/jquery.js"%3E%3C/script%3E'))</script>

    <script src="//ajax.googleapis.com/ajax/libs/jqueryui/1.8.9/jquery-ui.min.js"></script>
    <script>!window.jQuery && document.write(unescape('%3Cscript src="/javascripts/jquery-ui.js"%3E%3C/script%3E'))</script>

  ), :after => "<!-- Start Javascript includes -->"
end
