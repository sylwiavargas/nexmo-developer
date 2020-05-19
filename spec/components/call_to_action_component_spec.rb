require "rails_helper"

RSpec.describe CallToActionComponent, type: :component do
  context 'with valid inputs' do
    before(:all) do
      @component = described_class.new(data: valid_input)
    end

    it 'returns the assigned title' do
      expect(@component.assign_title).to eql('A Title')
    end

    it 'returns the assigned subtitle with HTML markup' do
      expect(@component.assign_subtitle).to eql('<p>A Subtitle</p>')
    end

    it 'returns the assigned url' do
      expect(@component.assign_url).to eql('/path')
    end

    it 'returns the assigned icon color' do
      expect(@component.assign_icon_color).to eql('blue')     
    end

    it 'returns the assigned icon name with path' do
      expect(@component.assign_icon_name).to eql('/symbol/volta-icons.svg#Vlt-icon-phone')     
    end

    it 'returns the assigned text' do
      expect(@component.assign_text).to eql('<p>Some text</p>')     
    end
  end

  context 'with missing required inputs' do
    it 'raises an exception for missing url input' do
      expect { described_class.new(data: missing_url_input) }.to raise_error("Missing 'url' key in call_to_action component")
    end

    it 'raises an exception for missing title input' do
      expect { described_class.new(data: missing_title_input) }.to raise_error("Missing 'title' key in call_to_action component")
    end

    it 'raises an exception for missing icon color input' do
      expect { described_class.new(data: missing_icon_color_input) }.to raise_error("Missing icon 'color' key in call_to_action component")
    end

    it 'raises an exception for missing icon name input' do
      expect { described_class.new(data: missing_icon_name_input) }.to raise_error("Missing icon 'name' key in call_to_action component")
    end
  end


  def valid_input
    {
      'title'=>'A Title', 
      'subtitle'=>'A Subtitle', 
      'icon'=>{
        'name'=>'icon-phone', 
        'color'=>'blue'
      }, 
      'url'=>'/path',
      'text'=>[
        {
          'type'=>'small',
          'content'=>'Some text'
        }
      ]
    }
  end

  def missing_url_input
    {
      'title'=>'A Title', 
      'subtitle'=>'A Subtitle', 
      'icon'=>{
        'name'=>'icon-phone', 
        'color'=>'blue'
      }, 
      'text'=>[
        {
          'type'=>'small',
          'content'=>'Some text'
        }
      ]
    }
  end

  def missing_title_input
    {
      'subtitle'=>'A Subtitle', 
      'icon'=>{
        'name'=>'icon-phone', 
        'color'=>'blue'
      }, 
      'url'=>'/path',
      'text'=>[
        {
          'type'=>'small',
          'content'=>'Some text'
        }
      ]
    }
  end

  def missing_icon_color_input
    {
      'subtitle'=>'A Subtitle', 
      'icon'=>{
        'name'=>'icon-phone', 
      }, 
      'url'=>'/path',
      'text'=>[
        {
          'type'=>'small',
          'content'=>'Some text'
        }
      ]
    }
  end

  def missing_icon_name_input
    {
      'subtitle'=>'A Subtitle', 
      'icon'=>{
        'color'=>'blue'
      }, 
      'url'=>'/path',
      'text'=>[
        {
          'type'=>'small',
          'content'=>'Some text'
        }
      ]
    }
  end
end
