require 'rubygems'
require 'parse_tree'
require 'sexp_processor'
require 'unified_ruby'

dir = File.dirname(__FILE__)
$LOAD_PATH << dir unless $LOAD_PATH.include?(dir)
require 'processing/assignment'
require 'processing/call'
require 'processing/conditional'
require 'processing/loop'
require 'processing/definition'
require 'scorer'

class Flog < SexpProcessor
  VERSION = '1.2.0'

  include UnifiedRuby

  THRESHOLD = 0.60


  @@no_class = :main
  @@no_method = :none

  attr_reader :options
  attr_accessor :class_stack, :method_stack

  def initialize(options)
    super()
    @options = options
    @class_stack = []
    @method_stack = []
    self.auto_shift_type = true
    self.require_empty = false # HACK
    @scorer = Scorer.new(options)
    reset
  end
  
  def parse_tree
    @parse_tree ||= ParseTree.new(false)
  end

  def flog_files(*files)
    files.flatten.each do |file|
      flog_file(file)
    end
  end
  
  def flog_file(file)
    return flog_directory(file) if File.directory? file
    if file == '-'
      raise "Cannot provide blame information for code provided on input stream." if options[:blame]
      data = $stdin.read
    end
    data ||= File.read(file)
    warn "** flogging #{file}" if options[:verbose]
    flog(data, file)
  end
  
  def flog_directory(dir)
    Dir["#{dir}/**/*.rb"].each {|file| flog_file(file) }
  end
  
  def flog(ruby, file)
    collect_blame(file) if options[:blame]
    process_parse_tree(ruby, file)
  rescue SyntaxError => e
    raise e unless e.inspect =~ /<%|%>/
    warn e.inspect + " at " + e.backtrace.first(5).join(', ') + 
      "\n...stupid lemmings and their bad erb templates... skipping"
  end
  
  def process_parse_tree(ruby, file)
    sexp = parse_tree.parse_tree_for_string(ruby, file)
    process Sexp.from_array(sexp).first
  end
  
  def collect_blame(filename)
  end
  
  def add_to_score(name)
    @scorer.add_to_score(name, class_name, method_name)
  end
    
  def penalize_by(bonus, &block)
    if block_given?
      @scorer.penalize_by(bonus, &block)
    else
      @scorer.penalize_by bonus
    end
  end

  def analyze_list(exp)
    process exp.shift until exp.empty?
  end

  def set_class(name)
    @class_stack.unshift name
    yield
    @class_stack.shift
  end

  def class_name
    @class_stack.first || @@no_class
  end

  def set_method(name)
    @method_stack.unshift name
    yield
    @method_stack.shift
  end

  def method_name
    @method_stack.first || @@no_method
  end

  def reset
    @scorer.reset
  end
  
  ##### remove later (should be in scorer)
  def multiplier
    @scorer.multiplier
  end
  
  def multiplier=(multi)
    @scorer.multiplier = multi
  end
  
  def calls
    @scorer.calls
  end
  
  def totals
    @scorer.totals
  end
  
  def total
    @scorer.total
  end
  
  def calls
    @scorer.calls
  end
  
  ##### remove later (should be in scorer)



  def output_summary(io)
    io.puts "Total Flog = %.1f (%.1f flog / method)\n" % [total, average]
  end

  def output_method_details(io, class_method, call_list)
    return 0 if options[:methods] and class_method =~ /##{@@no_method}/
    
    total = totals[class_method]
    io.puts "%s: (%.1f)" % [class_method, total]

    call_list.sort_by { |k,v| -v }.each do |call, count|
      io.puts "  %6.1f: %s" % [count, call]
    end

    total
  end

  def output_details(io, max = nil)
    my_totals = totals
    current = 0
    calls.sort_by { |k,v| -my_totals[k] }.each do |class_method, call_list|
      current += output_method_details(io, class_method, call_list)
      break if max and current >= max
    end
  end

  def report(io = $stdout)
    output_summary(io)
    return if options[:score]
    
    if options[:all]
      output_details(io)
    else
      output_details(io, total * THRESHOLD)
    end    
  ensure
    reset
  end

  ############################################################
  # Process Methods:

  include Flame::ConditionalProcessing
  include Flame::AssignmentProcessing
  include Flame::LoopProcessing
  include Flame::DefinitionProcessing
  include Flame::CallProcessing

end
