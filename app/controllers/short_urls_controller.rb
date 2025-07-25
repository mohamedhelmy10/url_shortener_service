class ShortUrlsController < ApplicationController

  before_action :set_short_url, only: [:decode]

  #POST /encode
  def encode
    original_url = short_url_params[:original_url]
    result = UrlShorteningService.encode(original_url)
    
    if result[:success]
      short_url = "#{request.base_url}/#{result[:short_url].short_code}"
      render json: {short_url: short_url}
    else
      render json: {error: "Failed to encode URL", details: result[:errors]}, status: :unprocessable_entity
    end
  end

  #GET /decode
  def decode
    if @short_url
      render json: {original_url: @short_url.original_url}
    else
      render json: {error: "Short URL not found"}, status: :not_found
    end
  end

  private

  def set_short_url
    @short_url = UrlShorteningService.decode(params[:short_code])
  end

  def short_url_params
    params.require(:short_url).permit(:original_url)
  end
end
