# Run with rails APP_NAME -J -d mysql -m

# Setup .rvmrc file for the project
rvmrc = <<-RVMRC
rvm_gemset_create_on_use_flag=1
rvm gemset use #{app_name}
RVMRC

create_file ".rvmrc", rvmrc

# Add some more stuff to the git ignore
append_file '.gitignore' do
  '.DS_Store'
end

puts "removing unneeded files..."
remove_file 'public/index.html'
remove_file 'public/robots.txt'
remove_file 'public/images/rails.png'
remove_file 'README'
run 'touch README'

# Use JQuery
get "http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js",  "public/javascripts/jquery.js"
get "http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.1/jquery-ui.min.js", "public/javascripts/jquery-ui.js"
get "http://github.com/rails/jquery-ujs/raw/master/src/rails.js", "public/javascripts/rails.js"
# base stylesheet
get "http://gist.github.com/raw/567195/b1d8c5f8250f63111e80d4dd31eb1eb0f4887217/base.css", "public/stylesheets/base.css"
run 'touch public/stylesheets/styles.css'

gsub_file 'config/application.rb', 'config.action_view.javascript_expansions[:defaults] = %w()', "config.action_view.javascript_expansions = { :defaults => ['jquery', 'jquery-ui', 'rails'] }"

# HTML5 Layout
layout = <<-LAYOUT
<!DOCTYPE html>
<html>
<head>
  <title>#{app_name.humanize}</title>
  <%= stylesheet_link_tag :all %>
  <%= javascript_include_tag :defaults %>
  <%= csrf_meta_tag %>
</head>
<body class="<%=controller_name%> <%=action_name%>">
  <ul id='user-links' class='nav'>
    <% if user_signed_in? %>
      <li><%= link_to current_user.email, edit_user_registration_path %></li>
      <li><%= link_to "logout", destroy_user_session_path %></li>
    <% else %>
      <li><%= link_to "sign in", new_user_session_path %></li>
      <li><%= link_to "sign up", new_user_registration_path %></li>
    <% end %>
  </ul>

  <% if !alert.blank? %>
    <p class="alert"><%= alert %></p>
  <% end %>
  <% if !notice.blank? %>
    <p class="notice"><%= notice %></p>
  <% end %>

  <%= yield %>
</body>
</html>
LAYOUT

remove_file "app/views/layouts/application.html.erb"
create_file "app/views/layouts/application.html.erb", layout

# so the directories end up in git
create_file "log/.gitkeep"
create_file "tmp/.gitkeep"



# The gems we like
puts "adding gems"
gem "responders"
gem "factory_girl", :group => :test

# Use the mysql2 gem
#gem "mysql2"
#gsub_file 'config/database.yml', 'mysql', 'mysql2'

# Use devise for user authentication
gem "devise", "1.1.2"

gem "will_paginate", :git => "git://github.com/mislav/will_paginate.git", :branch => "rails3"
gem "cancan"
gem "simple_form"

puts "running bundle install"
run 'bundle install'

puts "setting up Factory Girl"
# Use Factory Girl instead of Fixtures
inject_into_file 'test/test_helper.rb', "\nrequire 'factory_girl'", :after => "require 'rails/test_help'"
gsub_file 'test/test_helper.rb', 'fixtures :all', ''

factories = %q(
Factory.define :user do |f|
  f.sequence(:confirmation_token) {|n| "confirm#{n}" }
  f.sequence(:email)      {|n| "user#{n}@example.com" }
  f.sequence(:name)       {|n| "user#{n}" }
  f.sequence(:login)      {|n| "user#{n}" }
  f.password              "password"
  f.password_confirmation "password"
  f.confirmed_at          Time.now
end
)

create_file "test/factories.rb", factories

# Don't generate any fixtures
generators_configuration = %q(
    config.generators do |g|
      g.test_framework  :test_unit, :fixture => false
    end
)

environment generators_configuration

puts "Setting up Devise"
# Generate Devise
generate 'devise:install'
generate 'devise User'
generate 'devise:views'

puts "Add name and login to User model (and allowing login with email or login)"
inject_into_file 'app/models/user.rb', ", :name, :login", :after => ":remember_me"
inject_into_file 'app/models/user.rb', %q(
  validates_uniqueness_of :login, :allow_nil=>true
  validates_format_of :login, :with => /^[^@\s]*$/i, :message => "You can't have @ or spaces in your login" # Logins cannot have @ symbols or spaces

  def self.find_for_authentication(conditions={})
    return nil unless conditions[:login]
    if conditions[:login] =~ Devise.email_regexp # if it looks like an email that's how we'll treat it.
      conditions[:email] = conditions.delete(:login)
    end
    super
  end
), :before=> "end"

puts Dir.glob(destination_root + "/db/migrate/*_devise_create_users.rb")

inject_into_file Dir.glob(destination_root + "/db/migrate/*_devise_create_users.rb")[0], "\n      t.string :name, :login", :after=>'t.trackable'
gsub_file 'config/initializers/devise.rb', 'please-change-me@config-initializers-devise.com', "admin@#{app_name}.com"
gsub_file 'config/initializers/devise.rb', '# config.authentication_keys = [ :email ]', "config.authentication_keys = [ :login ]"

remove_file 'test/unit/user_test.rb'
create_file 'test/unit/user_test.rb', %q(
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @user = Factory(:user)
  end

  test "find_for_authentication returns user given email" do
    user = User.find_for_authentication(:login=>@user.email)

    assert_equal @user, user
    assert_equal @user.email, user.email
    assert_equal @user.name, user.name
  end

  test "find_for_authentication returns user given login" do
    user = User.find_for_authentication(:login=>@user.login)

    assert_equal @user, user
    assert_equal @user.email, user.email
    assert_equal @user.name, user.name
  end

  test "find_for_authentication with nil login" do
    Factory(:user, :login=>nil)
    user = User.find_for_authentication(:login=>nil)

    assert_nil user
  end

  test "display name" do
    @user = Factory(:user, :name=>"John", :email=>"jd@jd.com", :login=>"jd")
    assert_equal "John", @user.display_name
    @user.update_attributes!(:name=>"")
    assert_equal "jd", @user.display_name
    @user.update_attributes(:login=>nil)
    assert_equal "jd@jd.com", @user.display_name
  end

  test "login must be unique" do
    user = Factory.build(:user, :login=>@user.login)

    assert !user.save
    assert user.new_record?
    assert_equal ["has already been taken"], user.errors[:login]
  end
end
)

create_file 'test/integration/authentication_test.rb', %q(
require File.expand_path '../../test_helper', __FILE__

class AuthenticationTest < ActionController::IntegrationTest
  setup do
    @user = Factory(:user, :password=>"password", :password_confirmation=>"password")
    @user.confirmed_at = Time.now.to_s(:db)
    @user.save
  end

  test "authentication with email" do
    post '/users/sign_in', :user=>{:login=>@user.email, :password=>"password"}

    assert_response :redirect
    assert_equal @user.id, @integration_session.session["warden.user.user.key"].last
  end

  test "authentication with login" do
    post '/users/sign_in', :user=>{:login=>@user.login, :password=>"password"}

    assert_response :redirect
    assert_equal @user.id, @integration_session.session["warden.user.user.key"].last
  end

  test "signup" do
    assert_difference "User.count" do
      post '/users', :user=>{:email=>"mynewuser@example.com", :password=>"password"}

      assert_response :redirect
      assert_equal "You have signed up successfully. If enabled, a confirmation was sent to your e-mail.", @integration_session.session["flash"][:notice]
    end
  end
end
)

create_file 'lib/application_responder.rb', %q(
class ApplicationResponder < ActionController::Responder
  include Responders::FlashResponder
  include Responders::HttpCacheResponder
end
)

inject_into_file 'app/controllers/application_controller.rb', %q(
  self.responder = ApplicationResponder
  respond_to :html, :xml, :json

  before_filter :authenticate_user!
), :after => 'protect_from_forgery'

prepend_file 'app/controllers/application_controller.rb', "require \"application_responder\"\n"

gsub_file 'config/application.rb', '# config.autoload_paths += %W(#{config.root}/extras)', 'config.autoload_paths += %W( #{config.root}/lib )'

puts "Setting up Simple Form"
generate "simple_form:install"
gsub_file 'config/initializers/simple_form.rb', '# config.wrapper_tag = :div', '# config.wrapper_tag = :p'

puts "Use simple form in the devise views"

%w(confirmations/new passwords/edit passwords/new registrations/edit registrations/new sessions/new unlocks/new).each do |file|
  gsub_file "app/views/devise/#{file}.html.erb", 'form_for', 'simple_form_for'
  gsub_file "app/views/devise/#{file}.html.erb", '<p><%', '<%'
  gsub_file "app/views/devise/#{file}.html.erb", '%></p>', '%>'
  gsub_file "app/views/devise/#{file}.html.erb", '<br />', ''
  gsub_file "app/views/devise/#{file}.html.erb", 'f.password_field', 'f.input'
  gsub_file "app/views/devise/#{file}.html.erb", 'f.text_field', 'f.input'
  gsub_file "app/views/devise/#{file}.html.erb", 'f.submit', 'f.button :submit,'
  gsub_file "app/views/devise/#{file}.html.erb", /\s*<%= f\.label.*$/, ''
end

gsub_file "app/views/devise/registrations/edit.html.erb", ":password %>", %q(:password, :required => false, :hint=>"(leave blank if you don't want to change it)" %>)
gsub_file "app/views/devise/registrations/edit.html.erb", ":current_password %>", %q(:current_password, :required => false, :hint=>"(we need your current password to confirm your changes)", :error=>false %>)
gsub_file "app/views/devise/sessions/new.html.erb", "<%= f.input :email %>", %q(<%= f.input :login %>)

puts "adding user seed"
append_file "db/seeds.rb", %q(
user = User.new(:email=>"duff.john@gmail.com", :login=>'jduff', :password=>"jduff", :password_confirmation=>"jduff")
user.save!(:validate => false)
)

#----------------------------------------------------------------------------
# Create a home page
#----------------------------------------------------------------------------
puts "create a home controller and view"
generate(:controller, "home index")
gsub_file 'config/routes.rb', /get \"home\/index\"/, 'root :to => "home#index"'

gsub_file 'app/controllers/home_controller.rb', /def index/, %q(
  def index
    render :text => '', :layout => true)


# Git it Up
git :init
git :add => '.'
