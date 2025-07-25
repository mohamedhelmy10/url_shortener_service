class UrlShorteningService

  def self.encode(original_url)
    existing_short_url = ShortUrl.find_by(original_url: original_url)
    
    if existing_short_url
      { success: true, short_url: existing_short_url }
    else
      short_url = ShortUrl.new(original_url: original_url)
      if short_url.save
        { success: true, short_url: short_url }
      else
        { success: false, errors: short_url.errors.full_messages }
      end
    end
  end

  def self.decode(short_code)
    ShortUrl.find_by(short_code: short_code)
  end
end
