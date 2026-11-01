require "rails_helper"

RSpec.describe "Devise registration", type: :request do
  it "signs a new user up with a default budget" do
    expect {
      post user_registration_path, params: {
        user: { email: "new@example.com", password: "password123", password_confirmation: "password123" }
      }
    }.to change(User, :count).by(1)

    user = User.find_by!(email: "new@example.com")
    expect(user.budget.accounts.pluck(:name)).to eq([ "Default" ])
    expect(response).to redirect_to(root_path)
  end

  it "signs in and out" do
    user = create(:user)

    post user_session_path, params: { user: { email: user.email, password: "password123" } }
    expect(response).to redirect_to(root_path)

    delete destroy_user_session_path
    get root_path
    expect(response).to redirect_to(new_user_session_path)
  end
end
