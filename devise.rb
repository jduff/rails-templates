puts "Installing Devise"

gem "devise"

defer "gems" do
  puts "Setting up Devise"
  # Generate Devise
  generate 'devise:install'
  generate 'devise User login:string'
  generate 'devise:views'

  inject_into_file 'test/test_helper.rb', %q(

  class ActionController::TestCase
    include Devise::TestHelpers
  end), :after => "end"

  puts "Add name and login to User model (and allowing login with email or login)"
  inject_into_file 'app/models/user.rb', ", :login", :after => ":remember_me"
  inject_into_file 'app/models/user.rb', %q(
    validates_uniqueness_of :login, :allow_nil=>true
    validates_format_of :login, :with => /^[^@\s]*$/i, :message => "You can't have @ or spaces in your login" # Logins cannot have @ symbols or spaces

    # Case insensitive login/email
    before_validation do
      self.email = self.email.downcase if self.email
      self.login = self.login.downcase if self.login
    end

    def self.find_for_database_authentication(conditions)
      value = conditions[authentication_keys.first]
      where(["login = :value OR email = :value", { :value => value.downcase }]).first
    end
  ), :before => "end"

  # Add login to the devise migration
  gsub_file 'config/initializers/devise.rb', 'please-change-me@config-initializers-devise.com', "admin@#{app_name}.com"

  inject_into_file 'app/controllers/application_controller.rb', %q(

    before_filter :authenticate_user!
  ), :before => "end"

  puts "Adding User seed"
  append_file "db/seeds.rb", %q(
  user = User.new(:email=>"admin@example.com", :login=>'admin', :password=>"admin")
  user.save!(:validate => false)
  )

  gsub_file "config/routes.rb", /devise_for :users/, 'devise_for :users, :path_names => { :sign_up => "register", :sign_in => "login"}'

  inject_into_file "test/factories/users.rb", %q(
    f.sequence(:email)      {|n| "user#{n}@example.com" }
    f.sequence(:login)      {|n| "user#{n}" }
    f.password              "password"
    f.password_confirmation "password"), :after=>":user do |f|"
end


defer "layout" do
  inject_into_file 'app/views/layouts/application.html.erb', %q(
  <ul id='user-links' class='nav'>
    <% if user_signed_in? %>
      <li><%= link_to current_user.email, edit_user_registration_path %></li>
      <li><%= link_to "logout", destroy_user_session_path %></li>
    <% else %>
      <li><%= link_to "sign in", new_user_session_path %></li>
      <li><%= link_to "sign up", new_user_registration_path %></li>
    <% end %>
  </ul>), :after => "<header>"
end
