class DevController < ApplicationController
  skip_before_action :require_login

  def login
    user = User.find_or_create_by!(email: "dev@example.com") do |u|
      u.password = "password"
      u.password_confirmation = "password"
    end
    session[:user_id] = user.id
    cookies.signed[:uid] = { value: user.id, httponly: true, same_site: :lax }
    redirect_to root_path, notice: "開発用ログインを完了しました"
  end
end
