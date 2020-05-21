class FeaturedSessionComponent < ViewComponent::Base
  def initialize(data:)
    @data = data
  end

  def featured_session?
    @data['featured'] ? true : false
  end

  def assign_feature_title
    @data['featured']['title']
  end

  def assign_feature_video_url
    @data['featured']['video_url']
  end

  def assign_feature_description
    @data['featured']['description']
  end
end
