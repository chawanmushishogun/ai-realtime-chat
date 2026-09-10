class SharesController < ApplicationController
  skip_before_action :require_login

  def show
    @conversation = Conversation.find_signed!(params[:token], purpose: :share)
    render :show
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    render plain: "Link expired or invalid", status: :gone
  end
end
