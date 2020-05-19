class ActionButtonComponent < ViewComponent::Base
  def initialize(data:)
    @data = data

    check_config!
  end

  def center_button?
    @data['center_button']
  end

  def assign_button_type
    @data['type'] || 'primary'
  end

  def large_button?
    @data['large'] ? true : false
  end

  def assign_url
    @data['url']
  end

  def assign_text
    @data['text']
  end

  private

  def check_config!
    raise "missing 'url' key in action_button data" unless @data['url']
    raise "missing 'text' key in action_button data" unless @data['text']
  end
end
