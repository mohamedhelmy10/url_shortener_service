class CreateShortUrls < ActiveRecord::Migration[8.0]
  def change
    create_table :short_urls do |t|
      t.string :original_url, index: {unique: true}
      t.string :short_code, index: {unique: true}

      t.timestamps
    end
  end
end
