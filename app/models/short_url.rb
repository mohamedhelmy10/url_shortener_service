class ShortUrl < ApplicationRecord
  validates :original_url, presence: true, uniqueness: true, format: {with: URI::regexp(%w[http https]), message: "must be a valid URL"}
  validates :short_code, presence: true, uniqueness: true, length: {in: 6..10}

  before_validation :generate_short_code, on: :create

  private

  def generate_short_code
    return if short_code.present?

    loop do
      self.short_code = SecureRandom.alphanumeric(6)
      break unless ShortUrl.exists?(short_code: short_code)
    end
  end
end
