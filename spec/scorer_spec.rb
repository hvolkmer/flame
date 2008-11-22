require File.dirname(__FILE__) + '/spec_helper.rb'
require 'flog'
require 'sexp_processor'

describe Scorer do
  before :each do
    @options = { }
    @scorer = Scorer.new(@options)
  end

  describe 'when computing a score for a method' do
    it 'should require a hash of call tallies' do
      lambda { @scorer.score_method }.should raise_error(ArgumentError)
    end

    it 'should return a score of 0 if no tallies are provided' do
      @scorer.score_method({}).should == 0.0
    end

    it 'should compute the sqrt of summed squares for assignments, branches, and other tallies' do
      @scorer.score_method({
        :assignment => 7,
        :branch => 23,
        :crap => 37
        }).should be_close(Math.sqrt(7*7 + 23*23 + 37*37), 0.0000000001)
      end
    end

    describe 'when computing the average per-call flog score' do
      it 'should not allow arguments' do
        lambda { @scorer.average('foo') }.should raise_error(ArgumentError)
      end

      it 'should return the total flog score divided by the number of calls' do
        @scorer.stubs(:total).returns(100.0)
        @scorer.stubs(:calls).returns({ :bar => {}, :foo => {} })
        @scorer.average.should be_close(100.0/2, 0.00000000001)
      end
    end  


    describe 'when retrieving the total score' do
      it 'should take no arguments' do
        lambda { @scorer.total('foo') }.should raise_error(ArgumentError)
      end

      it 'should return 0 if nothing has been analyzed' do
        @scorer.total.should == 0
      end

      it 'should compute totals data when called the first time' do
        @scorer.expects(:totals)
        @scorer.total
      end

      it 'should not recompute totals data when called after the first time' do
        @scorer.total
        @scorer.expects(:totals).never
        @scorer.total
      end    
    end

    describe 'when recording a total for a method' do
      # guess what, @totals and @calls could be refactored to be first-class objects
      it 'should require a method and a score' do
        lambda { @scorer.record_method_score('foo') }.should raise_error(ArgumentError)
      end

      it 'should set the total score for the provided method' do
        @scorer.record_method_score('foo', 20)
        @scorer.totals['foo'].should == 20
      end
    end

    describe 'when updating the total flog score' do
      it 'should require an amount to update by' do
        lambda { @scorer.increment_total_score_by }.should raise_error(ArgumentError)
      end

      it 'should update the total flog score' do
        @scorer.increment_total_score_by 42
        @scorer.total.should == 42
      end
    end



    describe 'when compiling summaries for a method' do
      before :each do
        @tally = { :foo => 0.0 }
        @method = 'foo'
        @score = 42.0
        @scorer = Scorer.new({})
        @scorer.stubs(:score_method).returns(@score)
        @scorer.stubs(:record_method_score)
        @scorer.stubs(:increment_total_score_by)
      end

      it 'should require a method name and a tally' do
        lambda { @scorer.summarize_method('foo') }.should raise_error(ArgumentError)
      end

      it 'should compute a score for the method, based on the tally' do
        @scorer.expects(:score_method).with(@tally)
        @scorer.summarize_method(@method, @tally)
      end

      it 'should record the score for the method' do
        @scorer.expects(:record_method_score).with(@method, @score)
        @scorer.summarize_method(@method, @tally)      
      end

      it 'should update the overall flog score' do
        @scorer.expects(:increment_total_score_by).with(@score)
        @scorer.summarize_method(@method, @tally)            
      end

      describe 'ignoring non-method code and given a non-method tally' do
        it 'should not compute a score for the tally' do
          @scorer.expects(:score_method).never
          @scorer.summarize_method(@method, @tally)
        end

        it 'should not record a score based on the tally' do
          @scorer.expects(:record_method_score).never
          @scorer.summarize_method(@method, @tally)      
        end

        it 'should not update the overall flog score' do
          @scorer.expects(:increment_total_score_by).never
          @scorer.summarize_method(@method, @tally)            
        end
      end    
    end

    describe 'when requesting totals' do
      it 'should not accept any arguments' do
        lambda { @scorer.totals('foo') }.should raise_error(ArgumentError)
      end

      describe 'when called the first time' do
        # it 'should access calls data' do
        #   @scorer.expects(:calls).returns({})
        #   @scorer.totals
        # end

        it "will compile a summary for each method from the method's tally" do
          @calls = { :foo => 1.0, :bar => 2.0, :baz => 3.0 }
          @scorer.instance_variable_set(:@calls, @calls)
          @calls.each do |meth, tally|
            @scorer.expects(:summarize_method).with(meth, tally)
          end
          @scorer.totals
        end

        it 'should return the totals data' do
          @scorer.totals.should == {}
        end      
      end

      describe 'when called after the first time' do
        before :each do
          @scorer.totals
        end

        it 'should not access calls data' do
          @scorer.expects(:calls).never
          @scorer.totals        
        end

        it 'should not compile method summaries' do
          @scorer.expects(:summarize_method).never
          @scorer.totals
        end

        it 'should return the totals data' do
          @scorer.totals.should == {}
        end
      end
    end
  end


  describe 'when recursively analyzing the complexity of code' do
    before :each do
      @scorer = Scorer.new
    end
    
     it 'should require a complexity modifier value' do
       lambda { @scorer.penalize_by }.should raise_error(ArgumentError)
     end

     it 'should require a block, for code to recursively analyze' do
       lambda { @scorer.penalize_by(42) }.should raise_error(LocalJumpError)
     end

     it 'should recursively analyze the provided code block' do
       @scorer.penalize_by(42) do
         @foo = true
       end

       @foo.should be_true
     end

     it 'should update the complexity multiplier when recursing' do
       @scorer.multiplier = 1
       @scorer.penalize_by(42) do
         @scorer.multiplier.should == 43
       end
     end

     it 'when it is done it should restore the complexity multiplier to its original value' do
       @scorer.multiplier = 1
       @scorer.penalize_by(42) do
       end
       @scorer.multiplier.should == 1
     end
   end
