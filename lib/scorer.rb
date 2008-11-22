class Scorer

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

  attr_accessor :calls, :totals, :total_score, :multiplier, :options

  def initialize(options = {})
    @options = options
    @multiplier = 1.0
    @calls = {}
  end

  def reset
    @totals = @total_score = nil
    @multiplier = 1.0
    @calls = Hash.new { |h,k| h[k] = Hash.new 0 }
  end

  def add_to_score(name, class_name, method_name)
    @calls["#{class_name}##{method_name}"][name] += SCORES[name] * @multiplier
  end

  def penalize_by(bonus)
    @multiplier += bonus
    yield
    @multiplier -= bonus
  end

  def average
    return 0 if calls.size == 0
    total / calls.size
  end

  def total
    totals unless @total_score # calculates total_score as well
    @total_score
  end

  def totals
    unless @totals 
      @total_score = 0
      @totals = Hash.new(0)
      @calls.each {|meth, tally| summarize_method(meth, tally) }
    end
    @totals
  end

  # private methods!?
  def summarize_method(meth, tally)
    return if options[:methods] and meth =~ /##{@@no_method}$/
    score = score_method(tally)
    record_method_score(meth, score)
    increment_total_score_by score
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
  
end