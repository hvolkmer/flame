module Flame
  module CallProcessing

    def process_call(exp)
      penalize_by 0.2 do
        recv = process exp.shift
      end
      name = exp.shift
      penalize_by 0.2 do
        args = process exp.shift
      end

      add_to_score name

      s()
    end
    
    def process_super(exp)
      add_to_score :super
      analyze_list exp
      s()
    end

    def process_yield(exp)
      add_to_score :yield
      analyze_list exp
      s()
    end
  
    def process_iter(exp)
      context = (self.context - [:class, :module, :scope])
      if context.uniq.sort_by {|s|s.to_s} == [:block, :iter] then
        recv = exp.first
        if recv[0] == :call and recv[1] == nil and recv.arglist[1] and [:lit, :str].include? recv.arglist[1][0] then
          msg = recv[2]
          submsg = recv.arglist[1][1]
          set_method submsg do
            set_class msg do
              analyze_list exp
            end
          end
          return s()
        end
      end

      add_to_score :branch

      process exp.shift # no penalty for LHS

      penalize_by 0.1 do
        analyze_list exp
      end

      s()
    end
  
    def process_block(exp)
      penalize_by 0.1 do
        analyze_list exp
      end
      s()
    end

    # [:block_pass, [:lit, :blah], [:fcall, :foo]]
    def process_block_pass(exp)
      arg = exp.shift
      call = exp.shift

      add_to_score :block_pass

      case arg.first
      when :lvar, :dvar, :ivar, :cvar, :self, :const, :nil then
        # do nothing
      when :lit, :call then
        add_to_score :to_proc_normal
      when :iter, :and, :case, :else, :if, :or, :rescue, :until, :when, :while then
        add_to_score :to_proc_icky!
      else
        raise({:block_pass => [arg, call]}.inspect)
      end

      process arg
      process call

      s()
    end
  
  end
end