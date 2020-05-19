class CallToActionComponent < ViewComponent::Base
  def initialize(data:)
    @data = data

    check_config!
  end
  
  def assign_url
    @data['url']
  end

  def assign_icon_color
    @data['icon']['color']
  end

  def assign_icon_name
    if @data['icon']['name'].start_with?("Brand")
      "/symbol/volta-brand-icons.svg##{@data['icon']['name']}"
    else
      "/symbol/volta-icons.svg#Vlt-#{@data['icon']['name']}"
    end
  end

  def assign_title
    @data['title']
  end

  def assign_subtitle
    @data['subtitle'].render_markdown if @data['subtitle']
  end

  def assign_text
    if @data['text']
      @data['text'].each do |text|
        if text['type'] == 'large'
          return "
            <p class=\"p-large\">
            #{text['content'].render_markdown({skip_paragraph_surround: true})}
            </p>
          ".html_safe
        elsif text['type'] == 'small'
          return text['content'].render_markdown
        else 
          raise "Unknown text type: #{text['type']}"
        end
      end
    end
  end

  private

  def check_config!
    raise "Missing icon 'color' key in call_to_action component" unless @data['icon']['color']
    raise "Missing icon 'name' key in call_to_action component" unless @data['icon']['name']
    raise "Missing 'title' key in call_to_action component" unless @data['title']
    raise "Missing 'url' key in call_to_action component" unless @data['url']
  end
end
