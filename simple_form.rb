puts "Installing Simple Form"

gem "simple_form"

defer "gems" do
  generate "simple_form:install"
  gsub_file 'config/initializers/simple_form.rb', '# config.wrapper_tag = :div', 'config.wrapper_tag = :p'
end
