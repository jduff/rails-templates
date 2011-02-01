# Run with rails new APP_NAME -J -d mysql -m https://github.com/jduff/rails-templates/raw/master/all.rb
def apply_local(template, config={})
  apply File.join(File.dirname(__FILE__), template), config
end

@executed_bricks = []
@defered_bricks = []

def defer(*bricks, &block)
  @defered_bricks << [bricks.flatten, block]
end

def assemble(*bricks, &block)
  bricks.flatten.each do |brick|
    if @executed_bricks.include?(brick)
      raise "Attempting to invoke Brick multiple times!"
    else
      apply_local "#{brick}.rb"
      @executed_bricks << brick

      @defered_bricks.each do |b|
        b[0] = (b.first - @executed_bricks)

        b[1].call if b.first.empty?
      end

      @defered_bricks.delete_if{|b| b.first.empty?}
    end
  end

  block.call
end

bricks = %w(rvm cleanup factory_girl responders devise cancan simple_form layout compass jquery git gems)

assemble bricks do
  puts "Installing base gems"
  gem "ZenTest", :group => :test
  gem "autotest-rails", :group => :test

  gem "will_paginate", :git => "git://github.com/mislav/will_paginate.git", :branch => "rails3"

  gem "acts-as-taggable-on"
  gem "backpocket", :git => "git://github.com/jduff/backpocket.git"
end
