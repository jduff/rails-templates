gem "factory_girl", :group => :test
gem "factory_girl_rails", :group => :test
gem "rails3-generators" # To get the Factory Girl generator

remove_file 'test/fixtures'

environment %q(
    config.generators do |g|
      g.test_framework :test_unit, :fixture_replacement=>:factory_girl
    end
)
