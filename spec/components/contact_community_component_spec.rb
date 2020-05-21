require 'rails_helper'
require 'view_component/test_case'

RSpec.describe ContactCommunityComponent, type: :component do
  context 'with rendered data' do
    before(:all) do
      @result = render_inline(described_class.new(data: nil))
    end

    it 'creates an instance of the component class' do
      expect(described_class.new(data: nil)).to be_an_instance_of(ContactCommunityComponent)
    end

    it 'contains the expected text' do
      expect(@result.children.to_html).to include('<h2>Get in touch</h2>')
      expect(@result.children.to_html).to include('Drop us an email at <a href="mailto:community@vonage.com">community[at]vonage.com</a>')
      expect(@result.children.to_html).to include('Do you have a question or want us to support your tech community event?')
    end
  end
end
