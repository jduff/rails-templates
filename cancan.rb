puts "Installing CanCan for authorization"
gem "cancan" # authorization

create_file "app/models/ability.rb",
%q(class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # in case of guest

    # can :manage, Something, :user_id => user.id
    can :read, :all
  end
end)

inject_into_class "app/controllers/application_controller.rb" %q(
  # Use this method in your controllers to load and authorize resources with CanCan
  # load_and_authorize_resource

  # rescue_from CanCan::AccessDenied do |ex|
  #   flash[:alert] = ex.message
  #   redirect_to user_path(@user)
  # end
)

