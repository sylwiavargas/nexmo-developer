require 'rails_helper'
require 'view_component/test_case'

RSpec.describe ContactSupportComponent, type: :component do
  context 'with rendered data' do
    before(:all) do
      @result = render_inline(described_class.new(data: nil))
    end

    it 'creates an instance of the component class' do
      expect(described_class.new(data: nil)).to be_an_instance_of(ContactSupportComponent)
    end

    it 'contains the expected text' do
      expect(@result.children.to_html).to include('<h2>Do you have a question?</h2>')
      expect(@result.children.to_html).to include('<a href="https://www.nexmo.com/privacy-policy">Privacy Policy</a>')
      expect(@result.children.to_html).to include('Check out our <a href="https://help.nexmo.com/">support FAQs</a>')
    end
  end
end
