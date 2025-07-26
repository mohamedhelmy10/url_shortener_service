class UrlShorteningService

  def self.encode(original_url)
    short_url = ShortUrl.find_or_create_by(original_url: original_url)
    
    if short_url.persisted?
      { success: true, short_url: short_url }
    else
      { success: false, errors: short_url.errors.full_messages }
    end
  end

  def self.decode(short_code)
    ShortUrl.find_by(short_code: short_code)
  end
end
