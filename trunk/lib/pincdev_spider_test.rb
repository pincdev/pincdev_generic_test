# PincdevSpiderTest
module PincdevSpiderTest

  def spider_test(opts_in = {})
    opts = {
      :start => "/",
      :verbose => false,
      :show_source => true,
      :body_gsubs => {},
      :repeated_id_list => [],
      :exclude_regex => Regexp.union(/^[^\/]/,/logout/,/\/javascripts/,/\/stylesheets/),
      :skip_validation => /skip_validation/,
      :limit => 1000
    }.merge(opts_in)

    link_array = opts[:start].class == Array ? opts[:start] : [opts[:start]]
    link_sources = {}
    link_array.each{|link| link_sources[link] = ''}
    verbose = opts[:verbose]
    show_source = opts[:show_source]
    exclude_regex = opts[:exclude_regex]
    body_gsubs = opts[:body_gsubs]
    repeated_id_list = opts[:repeated_id_list]
    limit = opts[:limit]
    skip_validation = opts[:skip_validation]

    STDOUT.sync = true
    current = 0
    num_errors = 0
    link_array.each_index do |index|
      break if limit < current += 1
      link = link_array[index]
      print "#{index + 1}: #{link} from #{link_sources[link]}." if verbose
      get link
      begin
        if @response.redirected_to
          print "forwarded." if verbose
          new_url = forwarded(link)
          if ! link_array.index(new_url)
            link_array << new_url
            link_sources[new_url] = link
            puts "adding #{new_url} to list, for a total of #{link_array.length} (#{link_array.length - index - 1} left)" if verbose
          else
            puts "NOT adding #{new_url}." if verbose
          end
          
        else
          assert_response :success, "Response not success.(#{index}: #{link} from #{link_sources[link]})"
          if link.match(skip_validation)
            puts "validation skipped." if verbose
          else
            body = clean_html(@response.body, body_gsubs, repeated_id_list)

            extract_links(link_array, link_sources, body, exclude_regex, link)

            print "." if verbose

            response_text_with_numbers = show_source ? add_line_numbers(body) + "#{index}: #{link} " : ''

            print "." if verbose

            # Assert that the html is valid.  And if it is not, output an error with the html body source with line numbers.
            assert_valid_html body, "HTML not valid for #{link}.\n#{response_text_with_numbers}from #{link_sources[link]}" if body
            puts "valid." if verbose
          end
        end
      rescue Exception
        # This catches the errors/failures, adds the error message to the string, and allows the test to go on.
        puts "Caught exception."
        num_errors += 1
        ex_str = "#{link}: Error: " + $!.inspect
        $!.backtrace.each{|b| ex_str += "   " + b + "\n"}
        puts ex_str
      end
      assert_operator 10, :>, num_errors, "#{num_errors} Errors or Failures in the spider test.  " + 
        "NOTE: This error just exists to make the test stop after 10 errors, rather than keep going."
    end
    assert_equal 0, num_errors, "#{num_errors} Errors or Failures in the spider test.  NOTE: If you are looking at this in CruiseControl.rb you need to look in the build log for the error detail."
  end
     

  def extract_links(link_array, link_sources, body, regex, link)
    adds = 0
    matches = @response.body.scan(/href=\"([^"]*)\"/) do |m|
      if ! m[0].match(regex) and ! link_array.index(m[0])
        adds += 1
        link_array << m[0]
        link_sources[m[0]] = link
      end
    end
    link_array
  end


  def clean_html(body, body_gsubs, dup_ids)

    header, body = body.split("<body")

    body_gsubs.each do |p, r|
      body.gsub!(p, r)
    end

    body = header + "<body" + body

    # do away with the multiple ids until we can fix that.
    dup_ids.each do |id|
      i = 0
      while body.match(id)
        new_id = String.new(id)
        new_id.insert(id.length/2,i.to_s)
        body.sub!(id,new_id)
        i += 1
      end
      if i > 0
        new_id = String.new(id)
        new_id.insert(id.length/2,"0")
        body.sub!(new_id, id)
      end
    end
    body
  end


  def forwarded(link)
    # handle forwards.  Sometimes we have to add the controller.
    if @response.redirected_to.class == Hash
      @response.redirected_to[:controller] = link.split("/")[1] if @response.redirected_to.has_key?(:action) && ! @response.redirected_to.has_key?(:controller)
      new_url = "/#{@response.redirected_to[:controller]}/#{@response.redirected_to[:action]}"
      query_str_hash = @response.redirected_to.delete_if{|k,v| k == :controller || k == :action }
      query_str_hash.each_pair {|k,v| new_url += "&#{k}=#{v}"}
      new_url.sub!("&","?")
    else
      new_url = @response.redirected_to
    end
    new_url
  end


  def add_line_numbers(body)
    i = 0
    body.collect {|l| i += 1;i.to_s + ": " + l}.join()
  end
end 
