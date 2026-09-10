class ChatChannel < ApplicationCable::Channel
  def subscribed
    cid = params[:conversation_id]
    conversation = current_user.conversations.find_by(id: cid)
    reject_unauthorized_connection unless conversation
    stream_from stream_key(conversation.id)
  end

  private

  def stream_key(cid)
    "chat_u#{current_user.id}_c#{cid}"
  end
end
