require 'rails_helper'

RSpec.describe "ShortUrls", type: :request do
  describe "POST /encode" do
    let(:original_url) { 'https://codesubmit.io/library/react' }

    context "with a valid URL" do
      it "creates a short url and returns it" do
        post "/encode", params: { short_url: { original_url: original_url } }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["short_url"]).to match(%r{#{request.base_url}/\w{6,10}})
      end

      it "returns the same short url for the same original url" do
        post "/encode", params: { short_url: { original_url: original_url } }
        first_short_url = JSON.parse(response.body)["short_url"]
        post "/encode", params: { short_url: { original_url: original_url } }
        second_short_url = JSON.parse(response.body)["short_url"]
        expect(second_short_url).to eq(first_short_url)
      end
    end

    context "with an invalid URL" do
      it "returns an error and 422 status" do
        post "/encode", params: { short_url: { original_url: "not-a-url" } }
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Failed to encode URL")
        expect(json["details"]).to include("Original url must be a valid URL")
      end
    end
  end

  describe "GET /decode" do
    let!(:short_url) { create(:short_url, original_url: "https://www.decode-test.com") }

    it "returns the original url for a valid short code" do
      get "/decode", params: { short_code: short_url.short_code }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["original_url"]).to eq(short_url.original_url)
    end

    it "returns an error for an invalid short code" do
      get "/decode", params: { short_code: "invalidcode" }
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Short URL not found")
    end
  end
end
