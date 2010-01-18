require File.dirname(__FILE__) + '/spec_helper'

module Clot
  module AttributeSetter


    def set_attributes
      @id_string = @name_string = @params.shift

      if @params[0] && ! @params[0].match(/:/)
        @value_string = @params.shift
      end
      @params.each do |pair|
        pair = pair.split /:/
        case pair[0]
          when "value"
            @value_string = pair[1]
          when "accept"
            @accept_string = %{accept="#{CGI::unescape pair[1]}" }
          when "class"
            @class_string = %{class="#{pair[1]}" }
          when "onchange"
            @onchange_string = %{onchange="#{pair[1]}" }
          when "maxlength"
            @max_length_string = %{maxlength="#{pair[1]}" }
          when "disabled"
            @disabled_string = %{disabled="#{if (pair[1] == "true") then 'disabled' end}" }
          else
            personal_attributes(pair[0], pair[1])
        end
      end
    end
  end

  class InputTag < Liquid::Tag
    include AttributeSetter
    include TagHelper

    def personal_attributes(name,value)
      case name
        when "size"
          @size_string = %{size="#{value}" }
      end
    end

    def render(context)
      set_attributes
      unless @value_string.nil?
        @value_string = %{value="#{@value_string}" }
      end
      %{<input #{@accept_string}#{@disabled_string}#{@class_string}id="#{@id_string}" #{@max_length_string}name="#{@name_string}" #{@size_string}#{@onchange_string}type="#{@type}" #{@value_string}/>}
    end
  end

  class HiddenFieldTag < InputTag

    def initialize(name, params, tokens)
      @params = split_params(params)
      @type = "hidden"
      super
    end
  end

  class TextFieldTag < InputTag

    def initialize(name, params, tokens)
      @params = split_params(params)
      @type = "text"
      super
    end
  end

  class FileFieldTag < InputTag

    def initialize(name, params, tokens)
      @params = split_params(params)
      @type = "file"
      super
    end
  end

  class TextAreaTag < Liquid::Tag
    include AttributeSetter
    include TagHelper
    def personal_attributes(name,value)

      case name
        when "cols"
          @col_string = %{cols="#{value}" }
        when "rows"
          @row_string = %{ rows="#{value}"}
        when "size"
          size_array = value.split /x/
          @col_string = %{cols="#{size_array[0]}" }
          @row_string = %{ rows="#{size_array[1]}"}    
      end
    end    

    def initialize(name, params, tokens)
      @params = split_params(params)
      super
    end

    def render(context)
      set_attributes
      %{<textarea #{@disabled_string}#{@class_string}#{@col_string}id="#{@id_string}" name="#{@name_string}"#{@row_string}>#{@value_string}</textarea>}
    end
  end

  class SubmitTag < Liquid::Tag
    include AttributeSetter
    include TagHelper

    def render(context)
      set_attributes
      %{<input type="submit" name="submit" value="Save" />}
    end

    def initialize(name, params, tokens)
      @params = split_params(params)
      super
    end
  end

  class SelectTag < Liquid::Tag
    include AttributeSetter
    include TagHelper

    def personal_attributes(name,value)
      case name
        when 'multiple'
          @multiple_string = %{multiple="#{value == "true" ? "multiple" : ""}" }
      end
    end

    def initialize(name, params, tokens)
      @params = split_params(params)
      super
    end    

    def render(context)
      set_attributes
      %{<select #{@disabled_string}#{@class_string}id="#{@id_string}" #{@multiple_string}name="#{@name_string}#{unless @multiple_string.nil? then '[]' end}">#{@value_string}</select>}
    end
    
  end
end

Liquid::Template.register_tag('select_tag', Clot::SelectTag)
Liquid::Template.register_tag('text_field_tag', Clot::TextFieldTag)
Liquid::Template.register_tag('hidden_field_tag', Clot::HiddenFieldTag)
Liquid::Template.register_tag('file_field_tag', Clot::FileFieldTag)
Liquid::Template.register_tag('text_area_tag', Clot::TextAreaTag)
Liquid::Template.register_tag('submit_tag', Clot::SubmitTag)

describe "tags for forms that don't use models" do
  context "for submit_tag" do
    it "should take label" do
      tag = "{% submit_tag Save %}"
      tag.should parse_to('<input type="submit" name="submit" value="Save" />')
    end
  end

  context "for hidden_field_tag" do
    it "generates basic tag" do
      tag = "{% hidden_field_tag tags_list %}"
      tag.should parse_to('<input id="tags_list" name="tags_list" type="hidden" />')
    end

    it "generates basic tag with value" do
      tag = "{% hidden_field_tag token,VUBJKB23UIVI1UU1VOBVI@ %}"
      tag.should parse_to('<input id="token" name="token" type="hidden" value="VUBJKB23UIVI1UU1VOBVI@" />')
    end

    it "trims whitespace near commas" do
      tag = "{% hidden_field_tag token , VUBJKB23UIVI1UU1VOBVI@ %}"
      tag.should parse_to('<input id="token" name="token" type="hidden" value="VUBJKB23UIVI1UU1VOBVI@" />')
    end

    it "can have onchange attribute" do
      tag = "{% hidden_field_tag collected_input,,onchange:alert('Input collected!') %}"
      tag.should parse_to(%{<input id="collected_input" name="collected_input" onchange="alert('Input collected!')" type="hidden" value="" />})
    end
  
  end

  context "for select_tag" do
    it "should use single option" do
      tag = "{% select_tag people,<option>David</option> %}"
      tag.should parse_to('<select id="people" name="people"><option>David</option></select>');
    end

    it "should use multiple options" do
      tag = "{% select_tag count,<option>1</option><option>2</option><option>3</option><option>4</option> %}"
      tag.should parse_to('<select id="count" name="count"><option>1</option><option>2</option><option>3</option><option>4</option></select>');
    end

    it "should allow multiple selections" do
      tag = "{% select_tag colors,<option>Red</option><option>Green</option><option>Blue</option>,multiple:true %}"
      tag.should parse_to('<select id="colors" multiple="multiple" name="colors[]"><option>Red</option><option>Green</option><option>Blue</option></select>');

    end

    it "should have selected options" do
      tag = %{{% select_tag locations,<option>Home</option><option selected="selected">Work</option><option>Out</option> %}}
      tag.should parse_to(%{<select id="locations" name="locations"><option>Home</option><option selected="selected">Work</option><option>Out</option></select>})
    end

    it "should allow the setting of classes and multiple selections" do
      tag = %{{% select_tag access,<option>Read</option><option>Write</option>,multiple:true,class:form_input %}}
      tag.should parse_to('<select class="form_input" id="access" multiple="multiple" name="access[]"><option>Read</option><option>Write</option></select>')
    end

    it "should allow disabled" do
      tag = "{% select_tag destination,<option>NYC</option><option>Paris</option><option>Rome</option>,disabled:true %}"
      tag.should parse_to('<select disabled="disabled" id="destination" name="destination"><option>NYC</option><option>Paris</option><option>Rome</option></select>')
    end
    
  end

  context "for text_area_tag" do

    it "should create text area" do
      tag = "{% text_area_tag post %}"
      tag.should parse_to('<textarea id="post" name="post"></textarea>')
    end


    it "should create text area with input" do
      tag = "{% text_area_tag bio,This is my biography. %}"
      tag.should parse_to('<textarea id="bio" name="bio">This is my biography.</textarea>')
    end

    it "should create text area with will cols and rows" do
      tag = "{% text_area_tag body,rows:10,cols:25 %}"
      tag.should parse_to('<textarea cols="25" id="body" name="body" rows="10"></textarea>')
    end

    it "should create text area with input" do
      tag = "{% text_area_tag body,size:25x10 %}"
      tag.should parse_to('<textarea cols="25" id="body" name="body" rows="10"></textarea>')
    end    

    it "should set disabled" do
      tag = "{% text_area_tag description,Description goes here.,disabled:true %}"
      tag.should parse_to('<textarea disabled="disabled" id="description" name="description">Description goes here.</textarea>')
    end
    it "should set css class" do
      tag = "{% text_area_tag comment,class:comment_input %}"
      tag.should parse_to('<textarea class="comment_input" id="comment" name="comment"></textarea>')
    end
  end

  context "for file_field_tag" do
    it "should have generic name" do
      tag = "{% file_field_tag attachment %}"
      tag.should parse_to('<input id="attachment" name="attachment" type="file" />')      
    end
    it "should have take css class" do
      tag = "{% file_field_tag avatar,class:profile-input %}"
      tag.should parse_to('<input class="profile-input" id="avatar" name="avatar" type="file" />')
    end
    it "should be able to be disabled" do
      tag = "{% file_field_tag picture,disabled:true %}"
      tag.should parse_to('<input disabled="disabled" id="picture" name="picture" type="file" />')
    end
    it "should be able to have values set" do
      tag = "{% file_field_tag resume,value:~/resume.doc %}"
      tag.should parse_to('<input id="resume" name="resume" type="file" value="~/resume.doc" />')
    end

    it "should take accept value" do
      tag = "{% file_field_tag user_pic,accept:image/png%2Cimage/gif%2Cimage/jpeg %}"
      tag.should parse_to('<input accept="image/png,image/gif,image/jpeg" id="user_pic" name="user_pic" type="file" />')
    end

    it "should take multiple values" do
      tag = "{% file_field_tag  file,accept:text/html,class:upload,value:index.html %}"
      tag.should parse_to('<input accept="text/html" class="upload" id="file" name="file" type="file" value="index.html" />')
    end 
  end


  context "for text_field_tag" do
    it "should take regular name" do
      tag = "{% text_field_tag name %}"
      tag.should parse_to('<input id="name" name="name" type="text" />')
    end

    it "should take other value" do
      tag = "{% text_field_tag query,Enter your search query here %}"
      tag.should parse_to('<input id="query" name="query" type="text" value="Enter your search query here" />')
    end

    it "can take css class and leave off value" do
      tag = "{% text_field_tag request,class:special_input %}"
      tag.should parse_to('<input class="special_input" id="request" name="request" type="text" />')
    end

    it "can take size parameter and blank value" do
      tag = "{% text_field_tag address,,size:75 %}"
      tag.should parse_to('<input id="address" name="address" size="75" type="text" value="" />')
    end

    it "can take maxlength" do
      tag = "{% text_field_tag zip,maxlength:5 %}"
      tag.should parse_to('<input id="zip" maxlength="5" name="zip" type="text" />')
    end

    it "can take disabled option" do
      tag = "{% text_field_tag payment_amount,$0.00,disabled:true %}"
      tag.should parse_to('<input disabled="disabled" id="payment_amount" name="payment_amount" type="text" value="$0.00" />')      
    end

    it do
      tag = "{% text_field_tag ip,0.0.0.0,maxlength:15,size:20,class:ip-input %}"
      tag.should parse_to('<input class="ip-input" id="ip" maxlength="15" name="ip" size="20" type="text" value="0.0.0.0" />')
    end
  end
end