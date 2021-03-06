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
require 'report'

class Flog < SexpProcessor
  VERSION = '1.2.0'

  include UnifiedRuby

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
  
  ####### remove later (should be in scorer)
  # These methods delegate to scorer - mostly because of the specs
  # We need to refactor the specs so that they spec the scorer or
  # just test the interaction to the scorer
  def reset
    @scorer.reset
  end
  
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
  ##### end remove later ####

  def report(io = $stdout)
    the_report = Report.new(io, @scorer, options[:methods])
    report_options = { :print_only_score => options[:score], :print_all => options[:all]}
    the_report.print(report_options)
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
