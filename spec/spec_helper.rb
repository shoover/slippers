require 'spec'

$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'lib/slippers'
require 'ostruct'
require 'date'
require 'mocha'
require 'tempfile'

Spec::Runner.configure do |config|
  
end


Spec::Matchers.define :parse do |input|
  chain :and_eval do |obj, group|
    @obj = obj
    @group = group
  end
  chain :to do |result|
    @result = result
  end
  match do |parser|
    @tree = parser.parse(input)
    @tree.should_not be_nil
    @tree.eval(@obj, @group).should eql(@result)
  end
  failure_message_for_should do |parser|
    if @tree.nil?
      "failed to parse \"#{input}\""
    else
      "expected #{@tree.inspect} to evaluate #{@obj.inspect} to \"#{@result}\""
    end
  end
end
