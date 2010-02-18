require File.dirname(__FILE__) + '/spec_helper'

class Person
  def initialize(first, last)
    @first, @last = first, last
  end
  attr_reader :first, :last
  
end

describe SlippersParser do
  
  before(:each) do
    @parser = SlippersParser.new
  end

  it 'should parse the subtemplate found within the delimiters' do
    template = Slippers::Engine.new('template for this')
    template_with_underscore = Slippers::Engine.new('template with underscore')
    predefined_templates = {:template => template, :template_with_underscore => template_with_underscore, :template_2 => template}
    template_group = Slippers::TemplateGroup.new(:templates => predefined_templates)
    
    @parser.should parse('$template()$').and_eval(nil, template_group).to('template for this')
    @parser.should parse('$template_2()$').and_eval(nil, template_group).to('template for this')
    @parser.should parse('Stuff before $template()$ and after').and_eval(nil, template_group).to('Stuff before template for this and after')
    @parser.should parse('then there is $template_with_underscore()$').and_eval(nil, template_group).to('then there is template with underscore')
  end 

   it 'should apply the attribute to a subtemplate when parsing it' do
     person = OpenStruct.new({:name => Person.new('fred', 'flinstone')})
     subtemplate = Slippers::Engine.new('Hello $first$ $last$')
     template_group = Slippers::TemplateGroup.new(:templates => {:person => subtemplate})
     
     @parser.should parse('$name:person()$').and_eval(person, template_group).to('Hello fred flinstone')
   end
  
  it 'should parse an anonymous subtemplate' do
    @parser.should parse('$people:{template for this $name$}$').and_eval(:people => {:name => 'fred'}).to('template for this fred')
    @parser.should parse('$people:{template for this "$name$"}$').and_eval(:people => {:name => 'fred'}).to('template for this "fred"')
    @parser.should parse('${template for this $name$}$').and_eval(:name => 'fred').to('template for this fred')
  end
  
  it "should apply a list of objects to subtemplates" do
    people = [ Person.new('fred', 'flinstone'), Person.new('barney', 'rubble') ]
    subtemplate = Slippers::Engine.new('this is $first$ $last$ ')
    template_group = Slippers::TemplateGroup.new(:templates => {:person => subtemplate})
    object_to_render = OpenStruct.new({:people => people})

    @parser.should parse('$people:person()$').and_eval(object_to_render, template_group).to("this is fred flinstone this is barney rubble ")
  end

  it "should call the default missing handler when the subtemplate cannot be found and there is no template group" do
    Slippers::Engine::MISSING_HANDLER.call.should eql('')
    @parser.should parse("This is the unknown template $unknown()$!").and_eval(Person.new('fred', 'flinstone')).to("This is the unknown template !")
    @parser.should parse("This is the unknown template $first:unknown()$!").and_eval(Person.new('fred', 'flinstone')).to("This is the unknown template !")
  end
  
  it "should call the missing handler when the subtemplate cannot be found" do
    missing_handler = lambda { |template| "Warning: the template [#{template}] is missing" }
    template_group = Slippers::TemplateGroup.new(:missing_template_handler => missing_handler)
    @parser.should parse("This is the unknown template $unknown()$!").and_eval(:object, template_group).to("This is the unknown template Warning: the template [unknown] is missing!")
    @parser.should parse("This is the unknown template $first:unknown()$!").and_eval(Person.new('fred', 'flinstone'), template_group).to("This is the unknown template Warning: the template [unknown] is missing!")
  end
  
  it "should parse the file template from the template group" do
    template_group = Slippers::TemplateGroupDirectory.new(['spec/views'])
    name = OpenStruct.new({:first => 'fred', :last => 'flinestone'})
    people = OpenStruct.new({:fred => name})
    @parser.should parse("should parse $person/name()$").and_eval(name, template_group).to("should parse fred flinestone")
    @parser.should parse("should parse $fred:person/name()$").and_eval(people, template_group).to("should parse fred flinestone")
  end
  
  it 'should render the object if the keyword it is used' do
    supergroup = Slippers::TemplateGroup.new(:templates => {:bold => Slippers::Engine.new("<b>$it$</b>")})
    subgroup = Slippers::TemplateGroup.new(:templates => {}, :super_group => supergroup)
    @parser.should parse("<b>$it$</b>").and_eval("Sarah", subgroup).to('<b>Sarah</b>')
    @parser.should parse("$name:bold()$").and_eval({:name => "Sarah"}, subgroup).to('<b>Sarah</b>')
  end
end


