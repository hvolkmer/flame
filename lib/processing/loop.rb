module Flame
  module LoopProcessing
  
    def process_until(exp)
      add_to_score :branch
      penalize_by 0.1 do
        process exp.shift # cond
        process exp.shift # body
      end
      exp.shift # pre/post
      s()
    end

    def process_while(exp)
      add_to_score :branch
      penalize_by 0.1 do
        process exp.shift # cond
        process exp.shift # body
      end
      exp.shift # pre/post
      s()
    end
  
  end
end