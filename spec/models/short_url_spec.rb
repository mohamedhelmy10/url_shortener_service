require 'rails_helper'

RSpec.describe ShortUrl, type: :model do
  after(:each) do
    ShortUrl.delete_all
  end

  # Validations

  describe 'validations' do
    describe 'original_url validations' do
      subject { build(:short_url) }

      it { should validate_presence_of(:original_url) }
      it { should validate_uniqueness_of(:original_url) }

      it 'validates original_url format' do
        expect(build(:short_url, original_url: 'http://valid.com')).to be_valid
        expect(build(:short_url, original_url: 'https://valid.org/path')).to be_valid
        expect(build(:short_url, original_url: 'ftp://invalid.com')).to_not be_valid
        expect(build(:short_url, original_url: 'not-a-url')).to_not be_valid
        expect(build(:short_url, original_url: 'www.missing-protocol.com')).to_not be_valid
      end
    end

    describe 'short_code validations' do
      it 'validates uniqueness of short_code' do
        existing = create(:short_url)
        duplicate = build(:short_url, short_code: existing.short_code)
        duplicate.valid?
        expect(duplicate.errors[:short_code]).to include('has already been taken')
      end

      it 'validates length of short_code' do
        short_url = build(:short_url, short_code: '12345')
        short_url.save

        expect(short_url.errors[:short_code]).to include('is too short (minimum is 6 characters)')

        short_url = build(:short_url, short_code: '12345678901')
        short_url.save

        expect(short_url.errors[:short_code]).to include('is too long (maximum is 10 characters)')
      end
    end
  end

  # Callbacks

  describe 'callbacks' do
    describe '#generate_short_code' do
      it 'generates a short_code before creation if not provided' do
        short_url = build(:short_url)
        expect(short_url.short_code).to be_nil
        short_url.save
        expect(short_url.short_code).to_not be_nil
        expect(short_url.short_code.length).to be_between(6, 10).inclusive
      end

      it 'does not overwrite an existing short_code' do
        short_url = build(:short_url, short_code: 'custom123')
        short_url.save
        expect(short_url.short_code).to eq('custom123')
      end

      it 'generates a unique short_code if a collision occurs' do
        first_short_url = create(:short_url)
        first_code = first_short_url.short_code

        allow(SecureRandom).to receive(:alphanumeric).and_return(first_code, 'UNIQUE23')

        second_short_url = build(:short_url, original_url: 'http://example2.com')
        second_short_url.save
        expect(second_short_url.short_code).to eq('UNIQUE23')
      end
    end
  end
end
