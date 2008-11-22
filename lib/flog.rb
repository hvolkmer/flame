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

class Flog < SexpProcessor
  VERSION = '1.2.0'

  include UnifiedRuby

  THRESHOLD = 0.60
  SCORES = Hash.new(1)

  # various non-call constructs
  SCORES.merge!(:alias => 2,
                :assignment => 1,
                :block => 1,
                :block_pass => 1,
                :branch => 1,
                :lit_fixnum => 0.25,
                :sclass => 5,
                :super => 1,
                :to_proc_icky! => 10,
                :to_proc_normal => 5,
                :yield => 1,

  # eval forms
                :define_method => 5,
                :eval => 5,
                :module_eval => 5,
                :class_eval => 5,
                :instance_eval => 5,

  # various "magic" usually used for "clever code"
                :alias_method => 2,
                :extend => 2,
                :include => 2,
                :instance_method => 2,
                :instance_methods => 2,
                :method_added => 2,
                :method_defined? => 2,
                :method_removed => 2,
                :method_undefined => 2,
                :private_class_method => 2,
                :private_instance_methods => 2,
                :private_method_defined? => 2,
                :protected_instance_methods => 2,
                :protected_method_defined? => 2,
                :public_class_method => 2,
                :public_instance_methods => 2,
                :public_method_defined? => 2,
                :remove_method => 2,
                :send => 3,
                :undef_method => 2,

  # calls I don't like and usually see being abused
                :inject => 2)

  @@no_class = :main
  @@no_method = :none

  attr_reader :calls, :options
  attr_accessor :multiplier, :class_stack, :method_stack

  def initialize(options)
    super()
    @options = options
    @class_stack = []
    @method_stack = []
    self.auto_shift_type = true
    self.require_empty = false # HACK
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
    @calls["#{class_name}##{method_name}"][name] += SCORES[name] * @multiplier
  end
  
  def average
    return 0 if calls.size == 0
    total / calls.size
  end
  
  def penalize_by(bonus)
    @multiplier += bonus
    yield
    @multiplier -= bonus
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
    @totals = @total_score = nil
    @multiplier = 1.0
    @calls = Hash.new { |h,k| h[k] = Hash.new 0 }
  end

  def total
    totals unless @total_score # calculates total_score as well

    @total_score
  end

  def score_method(tally)
    a, b, c = 0, 0, 0
    tally.each do |cat, score|
      case cat
      when :assignment then a += score
      when :branch     then b += score
      else                  c += score
      end
    end
    Math.sqrt(a*a + b*b + c*c)
  end
  
  def record_method_score(method, score)
    @totals ||= Hash.new(0)
    @totals[method] = score
  end
  
  def increment_total_score_by(amount)
    @total_score ||= 0
    @total_score += amount
  end
  
  def summarize_method(meth, tally)
    return if options[:methods] and meth =~ /##{@@no_method}$/
    score = score_method(tally)
    record_method_score(meth, score)
    increment_total_score_by score
  end

  def totals
    unless @totals then
      @total_score = 0
      @totals = Hash.new(0)
      calls.each {|meth, tally| summarize_method(meth, tally) }
    end
    @totals
  end

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
