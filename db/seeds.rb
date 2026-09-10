user = User.find_or_create_by!(email: "user@example.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
end

user.conversations.find_or_create_by!(title: "Default Conversation")
