class Report
  # Really neccessary?
  @@no_method = :none
  
  THRESHOLD = 0.60
  
  def initialize(io, scorer, report_methods = false)
    @io = io
    @scorer = scorer
    @report_methods = report_methods
  end
  
  def print(options = {})
    output_summary

    return if options[:print_only_score]
    
    if options[:print_all]
      output_details
    else
      output_details(@scorer.total * THRESHOLD)
    end
  end
  
  def output_summary
    @io.puts "Total Flog = %.1f (%.1f flog / method)\n" % [@scorer.total, @scorer.average]
  end

  def output_details(max = nil)
    my_totals = @scorer.totals
    current = 0
    @scorer.calls.sort_by { |k,v| -my_totals[k] }.each do |class_method, call_list|
      current += output_method_details(class_method, call_list)
      break if max and current >= max
    end
  end
  
  def output_method_details(class_method, call_list)
    return 0 if @report_methods and class_method =~ /##{@@no_method}/
    
    total = @scorer.totals[class_method]
    @io.puts "%s: (%.1f)" % [class_method, total]

    call_list.sort_by { |k,v| -v }.each do |call, count|
      @io.puts "  %6.1f: %s" % [count, call]
    end

    total
  end
  
end