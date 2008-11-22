module Flame
  module AssignmentProcessing
  
    def process_iasgn(exp)
      add_to_score :assignment
      exp.shift # name
      process exp.shift # rhs
      s()
    end
  
    def process_lasgn(exp)
      add_to_score :assignment
      exp.shift # name
      process exp.shift # rhs
      s()
    end
  
    def process_dasgn_curr(exp)
      add_to_score :assignment
      exp.shift # name
      process exp.shift # assigment, if any
      s()
    end
  
    def process_attrasgn(exp)
      add_to_score :assignment
      process exp.shift # lhs
      exp.shift # name
      process exp.shift # rhs
      s()
    end

    def process_attrset(exp)
      add_to_score :assignment
      raise exp.inspect
      s()
    end
  
    def process_masgn(exp)
      add_to_score :assignment
      process exp.shift # lhs
      process exp.shift # rhs
      s()
    end
  
  end
end