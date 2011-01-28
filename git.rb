puts "Adding the project to git"

# Add some more stuff to the git ignore
append_file '.gitignore' do
  '.DS_Store'
end

# so the directories end up in git
create_file "log/.gitkeep"
create_file "tmp/.gitkeep"

# Git it Up
git :init
git :add => '.'
