puts "Removing unneeded files..."
remove_file 'public/index.html'
remove_file 'public/images/rails.png'
remove_file 'README'
run 'touch README'
