require 'rails_helper'

RSpec.describe UrlShorteningService do

  describe '.encode' do
    context 'when encoding a new URL' do
      let(:original_url) { 'https://www.new-url-for-encoding.com/path' }
      let(:result) { UrlShorteningService.encode(original_url) }
      let(:short_url_record) { result[:short_url] }

      it 'returns success status' do
        expect(result[:success]).to be true
      end

      it 'creates a new ShortUrl record' do
        expect { short_url_record }.to change(ShortUrl, :count).by(1)
      end

      it 'returns a persisted ShortUrl object' do
        expect(short_url_record).to be_persisted
      end

      it 'assigns the correct original_url' do
        expect(short_url_record.original_url).to eq(original_url)
      end

      it 'generates a short_code' do
        expect(short_url_record.short_code).to be_present
        expect(short_url_record.short_code.length).to be_between(6, 10).inclusive
      end
    end

    context 'when encoding an existing URL' do
      let!(:existing_short_url) { create(:short_url, original_url: 'https://www.existing-url.com') }
      let(:original_url) { 'https://www.existing-url.com' }

      let(:result) { UrlShorteningService.encode(original_url) }
      let(:short_url_record) { result[:short_url] }

      it 'returns success status' do
        expect(result[:success]).to be true
      end

      it 'does not create a new ShortUrl record' do
        expect { result }.to_not change(ShortUrl, :count)
      end

      it 'returns the existing ShortUrl object' do
        expect(short_url_record).to eq(existing_short_url)
      end

      it 'returns a persisted ShortUrl object' do
        expect(short_url_record).to be_persisted
      end
    end

    context 'when encoding an invalid URL' do
      let(:invalid_url) { 'not-a-valid-url' }
      let(:result) { UrlShorteningService.encode(invalid_url) }

      it 'does not create a ShortUrl record' do
        expect { result }.to_not change(ShortUrl, :count)
      end

      it 'returns failure status' do
        expect(result[:success]).to be false
      end

      it 'returns error messages' do
        expect(result[:errors]).to include("Original url must be a valid URL")
      end
    end
  end

  describe '.decode' do
    let!(:existing_short_url) { create(:short_url, original_url: 'https://www.decoded-url.com') }

    context 'when decoding a valid short code' do
      it 'returns the correct ShortUrl object' do
        found_short_url = UrlShorteningService.decode(existing_short_url.short_code)
        expect(found_short_url).to eq(existing_short_url)
      end
    end

    context 'when decoding a non-existent short code' do
      it 'returns nil' do
        found_short_url = UrlShorteningService.decode('nonexistent')
        expect(found_short_url).to be_nil
      end
    end
  end
end
