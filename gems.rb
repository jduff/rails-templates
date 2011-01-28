puts "Running bundle install"

inside app_name do
  run "gem install bundler"
  run "bundle install"
end
