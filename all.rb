# Run with rails new APP_NAME -J -d mysql -m http://github.com/jduff/rails-templates/raw/master/all.rb

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
remove_file 'test/fixtures'
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
gem "factory_girl_rails", :group => :test
gem "rails3-generators" # To get the Factory Girl generator
gem "ZenTest", :group => :test
gem "autotest-rails", :group => :test

# Use devise for user authentication
gem "devise", "1.1.2"

gem "will_paginate", :git => "git://github.com/mislav/will_paginate.git", :branch => "rails3"
gem "cancan" # authorization
gem "simple_form"

puts "running bundle install"
run 'bundle install'

# Use Factory Girl for fixtures
environment %q(
    config.generators do |g|
      g.test_framework :test_unit, :fixture_replacement=>:factory_girl
    end
)

puts "setting up CanCan"
create_file "app/models/ability.rb",
%q(class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # in case of guest

    # can :manage, Something, :user_id => user.id
    can :read, :all
  end
end)

puts "Setting up Devise"
# Generate Devise
generate 'devise:install'
generate 'devise User login:string'
generate 'devise:views'

inject_into_file 'test/test_helper.rb', %q(

class ActionController::TestCase
  include Devise::TestHelpers
end), :after => "end"

inject_into_file "test/factories/users.rb", %q(
  f.sequence(:email)      {|n| "user#{n}@example.com" }
  f.sequence(:login)      {|n| "user#{n}" }
  f.password              "password"
  f.password_confirmation "password"), :after=>":user do |f|"

puts "Add name and login to User model (and allowing login with email or login)"
inject_into_file 'app/models/user.rb', ", :login", :after => ":remember_me"
inject_into_file 'app/models/user.rb', %q(
  validates_uniqueness_of :login, :allow_nil=>true
  validates_format_of :login, :with => /^[^@\s]*$/i, :message => "You can't have @ or spaces in your login" # Logins cannot have @ symbols or spaces

  def self.find_for_database_authentication(conditions)
    value = conditions[authentication_keys.first]
    where(["login = :value OR email = :value", { :value => value }]).first
  end
), :before => "end"

# Add login to the devise migration
gsub_file 'config/initializers/devise.rb', 'please-change-me@config-initializers-devise.com', "admin@#{app_name}.com"

create_file 'lib/application_responder.rb', %q(
class ApplicationResponder < ActionController::Responder
  include Responders::FlashResponder
  include Responders::HttpCacheResponder
end)

inject_into_file 'app/controllers/application_controller.rb', %q(
  self.responder = ApplicationResponder
  respond_to :html, :xml, :json

  before_filter :authenticate_user!

  # Use this method in your controllers to load and authorize resources with CanCan
  # load_and_authorize_resource

  # rescue_from CanCan::AccessDenied do |ex|
  #   flash[:alert] = ex.message
  #   redirect_to user_path(@user)
  # end

  # Example of using the responders - this will render html, xml or json depending on the request
  # def show
  #   respond_with @user
  # end
), :before => "end"

prepend_file 'app/controllers/application_controller.rb', "require \"application_responder\"\n"

gsub_file 'config/application.rb', '# config.autoload_paths += %W(#{config.root}/extras)', 'config.autoload_paths += %W( #{config.root}/lib )'

puts "Setting up Simple Form"
generate "simple_form:install"
gsub_file 'config/initializers/simple_form.rb', '# config.wrapper_tag = :div', 'config.wrapper_tag = :p'

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

inject_into_file "app/views/devise/registrations/edit.html.erb", %q(, :required => false, :hint=>"(leave blank if you don't want to change it)" %>), :after=>":password"

inject_into_file "app/views/devise/registrations/edit.html.erb", %q(, :required => false, :hint=>"(we need your current password to confirm your changes)", :error=>false), :after=>":current_password"

inject_into_file "app/views/devise/sessions/new.html.erb", %q(, :required => false, :label=>"Login or Email"),
  :after=>"<%= f.input :email"

puts "adding user seed"
append_file "db/seeds.rb", %q(
user = User.new(:email=>"admin@example.com", :login=>'admin', :password=>"admin", :password_confirmation=>"jduff")
user.save!(:validate => false)
)

#----------------------------------------------------------------------------
# Create a home page
#----------------------------------------------------------------------------
puts "create a home controller and view"
generate(:controller, "home index")
inject_into_file 'config/routes.rb', "\n  root :to => \"home#index\"", :after => "devise_for :users"

inject_into_file 'app/controllers/home_controller.rb', "\n    render :text => '', :layout => true", :after => "def index"


# Git it Up
git :init
git :add => '.'
