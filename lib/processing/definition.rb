module Flame
  module DefinitionProcessing
  
    def process_module(exp)
      set_class exp.shift do
        analyze_list exp
      end
      s()
    end

    def process_class(exp)
      set_class exp.shift do
        @scorer.penalize_by 1.0 do
          supr = process exp.shift
        end
        analyze_list exp
      end
      s()
    end

    def process_defn(exp)
      set_method exp.shift do
        analyze_list exp
      end
      s()
    end

    def process_defs(exp)
      process exp.shift
      set_method exp.shift do
        analyze_list exp
      end
      s()
    end
  
    def process_alias(exp)
      process exp.shift
      process exp.shift
      add_to_score :alias
      s()
    end
  
    def process_sclass(exp)
      @scorer.penalize_by 0.5 do
        recv = process exp.shift
        analyze_list exp
      end

      add_to_score :sclass
      s()
    end
  
    def process_lit(exp)
      value = exp.shift
      case value
      when 0, -1 then
        # ignore those because they're used as array indicies instead of first/last
      when Integer then
        add_to_score :lit_fixnum
      when Float, Symbol, Regexp, Range then
        # do nothing
      else
        raise value.inspect
      end
      s()
    end
  
  end
end