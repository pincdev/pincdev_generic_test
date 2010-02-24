# PincdevValidationsTest
module PincdevValidationsTest

  def validations_test(opts_in = {})
    opts = {
      :verbose => false,
      :exclude => /exclude_me/,
      :limit => 10000,
    }.merge(opts_in)

    exclude = opts[:exclude]
    verbose = opts[:verbose]
    limit = opts[:limit]

    # models = `grep "< ActiveRecord::Base" #{Rails.root}/app/models/*.rb | grep -v "end" | awk '{print $2}'`
    # Dir.glob( Rails.root + '/app/models/*' ).each do |f| models << File.basename( f ).gsub( /^(.+).rb/, '\1')

    models = []

    Dir.new("#{Rails.root}/app/models").entries.sort.each do |file_name|
      if File.file?("#{Rails.root}/app/models/#{file_name}")
        File.open("#{Rails.root}/app/models/#{file_name}").each do |line|
          m = line.match(/class (\w*) < ActiveRecord::Base/)
          if m
            models << m[1]
            break
          end
        end
      end
    end

    error_list = []
    models.each do |class_name|
      next if class_name.match(exclude)
      class_name.strip!
      Kernel.const_get(class_name).transaction do
        begin
          table_name = Kernel.const_get(class_name).table_name
          # the following row only works for postgres.
          table_exists = ActiveRecord::Base.connection.tables.index(table_name)
          if table_exists
            objs = Kernel.const_get(class_name).find(:all, :limit => limit, :order => "random()")
            puts "#{class_name}: #{objs.length}" if verbose
            objs.each{|o| error_list << "Invalid fixture #{class_name} (#{o.id}): #{o.errors.full_messages}" if !o.valid?}
          else
            error_list << "No table for #{class_name}"
          end
        rescue
          error_list << "Caught exception while checking #{class_name}: #{$!}: #{$!.backtrace.detect{|b| b.match(/check_model_fixtures/)}.split("/")[0]}"
          raise ActiveRecord::Rollback
        end
      end
    end
    assert_equal 0, error_list.length, "\n\n *** Some validations failed ***\n------------------------------------\n * #{error_list.join(%Q{\n * })}\n\n"
  end
end
