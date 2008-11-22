module Flame
  module ConditionalProcessing

    def process_if(exp)
      add_to_score :branch
      process exp.shift # cond
      @scorer.penalize_by 0.1 do
        process exp.shift # true
        process exp.shift # false
      end
      s()
    end
  
    # TODO:  it's not clear to me whether this can be generated at all.
    def process_else(exp)
      add_to_score :branch
      @scorer.penalize_by 0.1 do
        analyze_list exp
      end
      s()
    end
  
    def process_when(exp)
      add_to_score :branch
      @scorer.penalize_by 0.1 do
        analyze_list exp
      end
      s()
    end
  
    def process_case(exp)
      add_to_score :branch
      process exp.shift # recv
      @scorer.penalize_by 0.1 do
        analyze_list exp
      end
      s()
    end
  
    def process_or(exp)
      add_to_score :branch
      @scorer.penalize_by 0.1 do
        process exp.shift # lhs
        process exp.shift # rhs
      end
      s()
    end
  
    def process_and(exp)
      add_to_score :branch
      @scorer.penalize_by 0.1 do
        process exp.shift # lhs
        process exp.shift # rhs
      end
      s()
    end
  
    def process_rescue(exp)
      add_to_score :branch
      @scorer.penalize_by 0.1 do
        analyze_list exp
      end
      s()
    end
  
  end
end