require File.dirname(__FILE__) + '/spec_helper.rb'
require 'flog'
require 'sexp_processor'

describe Report do
  before :each do
    @total_score = 2.0
    @average_score = 1.0
    @scorer = stub("Scorer", :total=> @total_score, :average => @average_score)
    @handle = stub("IO handle", :puts => nil)
    @report = Report.new(@handle, @scorer)
  end
  
  describe 'when producing a report summary' do

    it 'computes the total flog score' do
      @scorer.expects(:total).returns 42.0
      @report.output_summary
    end 
    
    it 'computes the average flog score' do
      @scorer.expects(:average).returns 1.0
      @report.output_summary
    end
    
    it 'outputs the total flog score to the handle' do
      @handle.expects(:puts).with do |string|
        string =~ Regexp.new(Regexp.escape("%.1f" % @total_score))
      end
      @report.output_summary
    end
    
    it 'outputs the average flog score to the handle' do
      @handle.expects(:puts).with do |string|
        string =~ Regexp.new(Regexp.escape("%.1f" % @average_score))
      end
      @report.output_summary
    end
  end
  
  describe 'when producing a detailed call summary report' do
    before :each do
      
      @calls = { :foo => {}, :bar => {}, :baz => {} }
      @totals = { :foo => 1, :bar => 2, :baz => 3 }
      @scorer = stub("Scorer", :total=> @total_score, 
                                :average => @average_score,
                                :totals => @totals, 
                                :calls => @calls,
                                :output_method_details => 5
                                )
      @report = Report.new(@handle, @scorer)
    end
    
    
    it 'should allow a threshold on the amount of detail to report' do
      lambda { @report.output_details(300) }.should_not raise_error(ArgumentError)
    end
      
    it 'retrieves the set of total statistics' do
      @scorer.expects(:totals).returns(@totals)
      @report.output_details
    end
    
    it 'retrieves the set of call statistics' do
      @scorer.expects(:calls).returns({})
      @report.output_details(@handle)      
    end

    it 'should output a method summary for each located method' do
      @calls.each do |meth, list|
        @report.expects(:output_method_details).with(meth, list).returns(5)
      end
      @report.output_details
    end
    
    describe 'if a threshold is provided' do
      it 'should only output details for methods until the threshold is reached' do
        @report.expects(:output_method_details).with(:baz, {}).returns(5)
        @report.expects(:output_method_details).with(:bar, {}).returns(5)
        @report.expects(:output_method_details).with(:foo, {}).never
        @report.output_details(10)
      end
    end
    
    describe 'if no threshold is provided' do
      it 'should output details for all methods' do
        @calls.each do |class_method, call_list|
          @report.expects(:output_method_details).with(class_method, call_list).returns(5)
        end
        @report.output_details
      end
    end
  end
  
  describe 'when reporting the details for a specific method' do
    before :each do
      @totals = { 'foo#foo' => 42.0, 'foo#none' => 12.0 }
      @scorer = stub("Scorer", :totals=> @totals)
      @data = { :assign => 10, :branch => 5, :case => 3 }
    end
            
    describe 'and ignoring non-method code' do
      before :each do
        @report = Report.new(@handle, @scorer, true)
      end
      
      describe 'and given non-method data to summarize' do
        it 'should not generate any output on the i/o handle' do
          @handle.expects(:puts).never
          @report.output_method_details('foo#none', @data)
        end
      
        it 'should return 0' do
          @report.output_method_details('foo#none', @data).should == 0.0
        end
      end
      
      describe 'and given method data to summarize' do
        it 'should return the total complexity for the method' do
          @report.output_method_details('foo#foo', @data).should == 42.0
        end
        
        it 'should output the overall total for the method' do
          @handle.expects(:puts).with do |string| 
            string =~ Regexp.new(Regexp.escape("%.1f" % 42.0))
          end
          @report.output_method_details('foo#foo', @data)
        end
        
        it 'should output call details for each call for the method' do
          @data.each do |call, count|
            @handle.expects(:puts).with do |string| 
              string =~ Regexp.new(Regexp.escape("%6.1f: %s" % [ count, call ]))
            end
          end
          @report.output_method_details('foo#foo', @data)
        end
      end
    end
    
    describe 'and not excluding non-method code' do
      before :each do
        @report = Report.new(@handle, @scorer)
      end

      it 'should return the total complexity for the method' do
        @report.output_method_details('foo#foo', @data).should == 42.0
      end
      
      it 'should output the overall total for the method' do
        @handle.expects(:puts).with do |string| 
          string =~ Regexp.new(Regexp.escape("%.1f" % 42.0))
        end
        @report.output_method_details('foo#foo', @data)
      end
      
      it 'should output call details for each call for the method' do
        @data.each do |call, count|
          @handle.expects(:puts).with do |string| 
            string =~ Regexp.new(Regexp.escape("%6.1f: %s" % [ count, call ]))
          end
        end
        @report.output_method_details('foo#foo', @data)
      end
    end
  end
  
  describe 'when generating a report' do
    before :each do
      @report.stubs(:output_summary)
    end

    describe 'and producing a summary report' do
      before :each do
        @report.stubs(:output_summary)
      end
      
      it 'produces an output summary' do
        @report.expects(:output_summary)
        @report.print(:print_only_score => true)
      end
      
      it 'does not output a detailed report' do
        @report.expects(:output_details).never
        @report.print(:print_only_score => true)
      end

    end
    
    describe 'and producing a full report' do
      before :each do
        @report.stubs(:output_summary)
        @report.stubs(:output_details)
      end
      
      it 'produces an output summary' do
        @report.expects(:output_summary)
        @report.print(:print_only_score => false)
      end
      
      it 'should generate a detailed report of method complexity' do
        @report.expects(:output_details) 
        @report.print(:print_only_score => false)
      end

      describe 'when flogging all methods in the system' do
        before :each do
          @report.stubs(:output_summary)
          @report.stubs(:output_details)
        end
        
        it 'should not limit the detailed report' do
          @report.expects(:output_details)
          @report.print(:print_only_score => false, :print_all => false)
        end
      end
      
      describe 'when flogging only the most expensive methods in the system' do
        it 'should limit the detailed report to the Flog threshold' do
          @scorer.stubs(:total).returns(3.45)
          @report.expects(:output_details).with(3.45 * 0.60)
          @report.print(:print_only_score => false, :print_all => false)
        end
      end
    end
  end

end