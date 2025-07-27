require 'rails_helper'

RSpec.describe 'Rate Limiting', type: :request do
  before do
    # Reset rate limiting cache
    Rails.cache.clear
    Rack::Attack.cache.store.clear
  end

  describe 'Encode endpoint rate limiting' do
    it 'allows encode requests within the limit' do
      2.times do
        post '/encode', params: { short_url: { original_url: 'https://example.com' } }
        expect(response).to have_http_status(:ok)
      end
    end

    it 'blocks encode requests when rate limit is exceeded' do
      3.times do
        post '/encode', params: { short_url: { original_url: 'https://example.com' } }
      end

      expect(response).to have_http_status(:too_many_requests)
      expect(JSON.parse(response.body)).to include(
        'error' => 'Rate limit exceeded',
        'message' => 'Too many requests. Please try again later.'
      )
    end
  end

  describe 'Decode endpoint rate limiting' do
    let!(:short_url) { create(:short_url, original_url: "https://example.com") }

    it 'allows decode requests within the limit' do
      5.times do
        get '/decode', params: { short_code: short_url.short_code }
        expect(response).to have_http_status(:ok)
      end
    end

    it 'blocks decode requests when rate limit is exceeded' do
      6.times do
        get '/decode', params: { short_code: short_url.short_code }
      end

      expect(response).to have_http_status(:too_many_requests)
      expect(JSON.parse(response.body)).to include(
        'error' => 'Rate limit exceeded',
        'message' => 'Too many requests. Please try again later.'
      )
      expect(response.headers['Retry-After']).to be_present
    end
  end
end
