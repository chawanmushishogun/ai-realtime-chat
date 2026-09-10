class ConversationsController < ApplicationController
  before_action :set_conversation, only: [:show, :edit, :update, :destroy, :preset, :retitle, :share, :archive]
  before_action :set_conversations, only: [:index, :show]

  def index
    @conversation = @conversations.first || current_user.conversations.create!(title: "New conversation")
    render :show
  end

  def show; end

  def create
    convo = current_user.conversations.create!(title: "New conversation")
    redirect_to conversation_path(convo)
  end

  def edit; end

  def update
    if params[:preset].present?
      p = PROMPT_PRESETS[params[:preset]]
      @conversation.system_prompt = p[:system] if p
    end
    if @conversation.update(conversation_params)
      redirect_to conversation_path(@conversation), notice: "設定を更新しました"
    else
      flash.now[:alert] = @conversation.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @conversation.destroy
    redirect_to conversations_path, notice: "会話を削除しました"
  end

  def retitle
    title = Ai::TitleGenerator.new(@conversation).call
    @conversation.update!(title: title)
    redirect_to conversation_path(@conversation), notice: "タイトルを更新しました"
  end

  def share
    token = @conversation.signed_id(purpose: :share, expires_in: 7.days)
    render json: { url: shared_conversation_url(token: token), expires_at: 7.days.from_now.iso8601 }
  end

  def archive
    if @conversation.archived_at?
      @conversation.update!(archived_at: nil)
      redirect_to conversation_path(@conversation), notice: "アーカイブを解除しました"
    else
      @conversation.update!(archived_at: Time.current)
      redirect_to conversations_path, notice: "会話をアーカイブしました"
    end
  end

  def preset
    if params[:preset].present?
      preset = PROMPT_PRESETS[params[:preset]]
      @preset_system_prompt = preset[:system] if preset
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:id])
  end

  def set_conversations
    @q = params[:q].to_s
    scope = current_user.conversations.active.order(updated_at: :desc)
    @conversations = @q.present? ? scope.where("title ILIKE ?", "%#{@q}%") : scope
  end

  def conversation_params
    params.require(:conversation).permit(:system_prompt, :model, :temperature, :top_p, :presence_penalty, :frequency_penalty)
  end
end
