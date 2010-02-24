# PincdevModelMethodsTest
module PincdevModelMethodsTest

  def model_methods_test(opts_in)
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
