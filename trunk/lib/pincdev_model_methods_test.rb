# PincdevModelMethodsTest

# This module runs all model class methods in a rails app that do not have parameters
#
# Author::    Nick Roosevelt (mailto:nroose@thepinc.com)
# Copyright:: Copyright (c) 2010 PINC Solutions, Inc. (www.pincsolutions.com)
# License::   Distributes under the same terms as Ruby
#
# invoke it by having an integration test something like:
# 
#   require File.dirname(__FILE__) + '/../test_helper'
#
#   class ModelMethodsTest < Test::Unit::TestCase
#     include PincdevModelMethodsTest
#     fixtures :users, :customers, :products
#
#     def test_class_methods
#       model_methods_test()
#     end
#                
#   end
module PincdevModelMethodsTest

  # Run the model methods test.  Optional parameters (with their default values):
  #       :verbose => false
  #       :exclude => []  (This is an array of names of methods to exclude, for example: ["Customer.exclude_me"].
  def model_methods_test(opts_in = {})
    opts = {
      :verbose => false,
      :exclude => []
    }.merge(opts_in)
    exclude = opts[:exclude] + ['']
    verbose = opts[:verbose]
    
    # get list of methods
    class_methods = `ruby -pe 'next if not /^[^#]*def [A-Z][^.]*\.[^(\s]*\s*$/' #{RAILS_ROOT}/app/models/*.rb | awk '{print $2}'`

    # call them
    class_methods.each do |class_method|
      class_method.chomp!
      if !exclude.index(class_method)
        puts class_method if verbose
        eval class_method
      end
    end

  end

end
