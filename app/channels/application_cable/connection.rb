module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      uid = cookies.signed[:uid] || request.session[:user_id]
      user = User.find_by(id: uid)
      Rails.logger.info(action_cable_connect_uid: uid, found: user.present?)
      user || reject_unauthorized_connection
    end
  end
end
