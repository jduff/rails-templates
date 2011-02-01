gem 'compass'
gem 'compass-960-plugin'

defer "gems" do
  run "echo Y | compass init rails . --prepare -r ninesixty --css-dir public/stylesheets -q"

  directory "#{File.dirname(__FILE__)}/resources/compass/stylesheets", "app/stylesheets"

  run "compass compile"

  # Not sure why this dir is being made
  run "rm -rf #{app_name}"
end
