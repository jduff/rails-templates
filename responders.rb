gem "responders"

create_file 'lib/application_responder.rb', %q(
class ApplicationResponder < ActionController::Responder
  include Responders::FlashResponder
  include Responders::HttpCacheResponder
end)

prepend_file 'app/controllers/application_controller.rb', "require \"application_responder\"\n"

inject_into_file 'app/controllers/application_controller.rb', %q(
  self.responder = ApplicationResponder
  respond_to :html, :xml, :json

  # Example of using the responders - this will render html, xml or json depending on the request
  # def show
  #   respond_with @user
  # end
), :before => "end"

puts "Add lib to the autoload path"
gsub_file 'config/application.rb', '# config.autoload_paths += %W(#{config.root}/extras)', 'config.autoload_paths += %W( #{config.root}/lib )'

