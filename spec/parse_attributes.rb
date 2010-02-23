# coding:utf-8
require File.dirname(__FILE__) + '/spec_helper'

describe SlippersParser do
  
  before(:each) do
    @parser = SlippersParser.new
  end

  it "should return the string unparsed when there are no keywords in it" do
    @parser.should parse('').and_eval(nil).to('')
    @parser.should parse('  ').and_eval(nil).to('  ')
    @parser.should parse('this should be returned unchanged').and_eval.to('this should be returned unchanged')
    @parser.should parse(' this should be returned unchanged ').and_eval.to(' this should be returned unchanged ')
    @parser.should parse('this should be 1234567890 ').and_eval.to('this should be 1234567890 ')
    @parser.should parse('this should be abc1234567890 ').and_eval.to('this should be abc1234567890 ')
    @parser.should parse('this should be !@¬£%^&*()').and_eval.to('this should be !@¬£%^&*()')
  end
  
  it 'should find the keyword within the delimiters' do
    message = OpenStruct.new({:message => 'the message', :message2 => 'the second message', :name => 'fred', :full_name => 'fred flinstone'})
    @parser.should parse('$message$').and_eval(message).to('the message')
    @parser.should parse('$message$ for $name$').and_eval(message).to('the message for fred')
    @parser.should parse('we want to find $message$').and_eval(message).to('we want to find the message')
    @parser.should parse('$message$ has spoken').and_eval(message).to('the message has spoken')
    @parser.should parse('Yes! $message$ has spoken').and_eval(message).to('Yes! the message has spoken')
    @parser.should parse('Yes! $full_name$ has spoken').and_eval(message).to('Yes! fred flinstone has spoken')
    @parser.should parse('Yes! $message2$ has spoken').and_eval(message).to('Yes! the second message has spoken')
    @parser.should parse('Yes! "$message2$" has spoken').and_eval(message).to('Yes! "the second message" has spoken')
    @parser.should_not parse('$$')
  end
  
  it 'should not match on escaped delimiters' do
    @parser.should parse('stuff \$notmatched\$').and_eval(stub(:nothing)).to('stuff $notmatched$')
  end
  
  it "should render a list of objects" do
    people = [OpenStruct.new({:name => 'fred'}), OpenStruct.new({:name => 'barney'}) ]
    @parser.parse('this is $name$').eval(people).should eql('this is fredbarney')
    @parser.should parse('this is $name$').and_eval(people, nil).to("this is fredbarney")
  end
  
  it "should render the default string when the attribute cannot be found on the object to render and there is no template group" do  
    Slippers::Engine::DEFAULT_STRING.should eql('') 
    @parser.should parse("This is the $adjective$ template with $message$.").and_eval(OpenStruct.new).to("This is the  template with .")
    @parser.should parse("$not_me$").and_eval(stub()).to('')
  end  
  
  it "should render the default string of the template group when the attribute cannot be found on the object to render" do  
    template_group = Slippers::TemplateGroup.new(:default_string => "foo" )
    template_group.default_string.should eql('foo')
    @parser.should parse("$not_me$").and_eval(stub(), template_group).to('foo')
  end
  
  it "should convert attribute to string" do
    fred = OpenStruct.new({:name => 'fred', :dob => DateTime.new(1983, 1, 2)})
    template_group = Slippers::TemplateGroup.new(:templates => {:date => Slippers::Engine.new('$year$')} )
    @parser.should parse("This is $name$ who was born in $dob:date()$").and_eval(fred, template_group).to('This is fred who was born in 1983')
  end

  it "should render a hash" do
    hash_object = {:title => 'Domain driven design', :author => 'Eric Evans', :find => 'method on a hash'}
    @parser.should parse("should parse $title$ by $author$").and_eval(hash_object).to("should parse Domain driven design by Eric Evans")
    @parser.should parse("should parse a symbol before a $find$").and_eval(hash_object).to('should parse a symbol before a method on a hash')
  end

  it "should render a symbol on a hash before its methods" do
    hash_object = {:find => 'method on a hash'}
    @parser.should parse("should parse a symbol before a $find$").and_eval(hash_object).to('should parse a symbol before a method on a hash')
    @parser.should parse("should still render the method $size$").and_eval(hash_object).to('should still render the method 1')
  end

  it "should render a hash symbol containing an embedded keyword" do
    hash_object = {:modifier => 'mod'}
    @parser.should parse("$modifier$").and_eval(hash_object).to('mod')
  end

  it 'should not parse if the template is not correctly formed' do
    @parser.should_not parse("$not_properly_formed")
  end  
  
  it 'should use the specified expression options to render list items' do
    @parser.should parse('$list; null="-1", separator=", "$').and_eval(:list => [1,2,nil,3]).to("1, 2, -1, 3")
    @parser.should parse('$list; separator=", "$').and_eval(:list => [1,2,3]).to("1, 2, 3")
    @parser.should parse('$list; separator="!!"$').and_eval(:list => [1,2,3,nil]).to("1!!2!!3")
    @parser.should parse('$list; null="-1"$').and_eval(:list => [1,nil,3]).to("1-13")
  end
  
  it 'should render separators with special escapes' do
    @parser.should parse('$list; separator="\n"$').and_eval(:list => [1,2,3]).to("1\n2\n3")
    @parser.should parse('$list; separator="\n\t"$').and_eval(:list => [1,2,3]).to("1\n\t2\n\t3")
  end

  it 'should conditionally parse some text' do
    @parser.should parse("$if(greeting)$ Hello $end$").and_eval(:greeting => true).to(" Hello ")
    @parser.should parse("$if(greeting)$ Hello $end$").and_eval(:greeting => false).to("")
    @parser.should parse("$if(greeting)$ Hello $end$").and_eval(:greeting => nil).to("")
    @parser.should parse("$if(greeting)$Hello$else$Goodbye$end$").and_eval(:greeting => true).to("Hello")
    @parser.should parse("$if(greeting)$ Hello $else$ Goodbye $end$").and_eval(:greeting => false).to(" Goodbye ")
    @parser.should parse("$if(greeting)$ Hello $end$").and_eval(:greetingzzzz => true).to("")
    @parser.should parse("$if(show)$$if(greeting)$ $greeting$ $end$$end$").and_eval(:show => true, :greeting => 'Hello').to(' Hello ')
  end

  it 'should conditionally parse a template' do
    @parser.should parse("$if(greeting)$ $greeting$ $end$").and_eval(:greeting => 'Hi').to(" Hi ")
    @parser.should parse("$if(greeting)$$greeting$ $else$ Nothing to see here $end$").and_eval(:greeting => 'Hi').to("Hi ")
  end

  it 'should parse templates in nested conditionals' do
    @parser.should parse("$if(greeting)$$greeting$ $else$ Nothing to see here $end$").and_eval(:greeting => nil).to(" Nothing to see here ")
  end
end


