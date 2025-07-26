FactoryBot.define do
  factory :short_url do
    sequence(:original_url) { |n| "https://example.com/long/path/for/test_#{n}" }
    short_code { nil }
  end
end
