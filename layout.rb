inside "app/views/layouts" do
  remove_file 'application.html.erb'
  get "#{File.dirname(__FILE__)}/resources/layout/application.html.erb", "application.html.erb"
end

remove_file 'public/favicon.ico'
remove_file 'public/robots.txt'

directory "#{File.dirname(__FILE__)}/resources/layout/public", "public"

# Update the template with the app name
inject_into_file 'app/views/layouts/application.html.erb', app_name.humanize, :after => "<title>"
