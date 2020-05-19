require "rails_helper"

RSpec.describe ActionButtonComponent, type: :component do
  context 'with valid inputs' do
    before(:all) do
      @component = described_class.new(data: valid_input)
    end

    it 'returns the assigned text' do
      expect(@component.assign_text).to eql('An action button')
    end

    it 'returns the assigned url' do
      expect(@component.assign_url).to eql('https://dashboard.nexmo.com/sign-up')
    end

    it 'properly assigns the boolean value for centering the component' do
      expect(@component.center_button?).to eql(true)
    end

    it 'assigns a default button type if one is not provided' do
      expect(@component.assign_button_type).to eql('primary')
    end

    it 'properly assigns the boolean value for button size' do
      expect(@component.large_button?).to eql(false)
    end
  end

  context 'with missing required inputs' do
    it 'raises an exception for missing url input' do
      expect { described_class.new(data: missing_url_input) }.to raise_error("missing 'url' key in action_button data")
    end

    it 'raises an exception for missing text input' do
      expect { described_class.new(data: missing_text_input) }.to raise_error("missing 'text' key in action_button data")
    end
  end


  def valid_input
    {
      'text'=>'An action button', 
      'url'=>'https://dashboard.nexmo.com/sign-up', 
      'center_button'=>true
    }
  end

  def missing_url_input
    {
      'text'=>'An action button',
      "center_button"=>true
    }
  end

  def missing_text_input
    {
      'url'=>'https://dashboard.nexmo.com/sign-up', 
      'center_button'=>true
      }
  end
end
