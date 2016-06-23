# some basic helpers to simulate devise controller methods in specs
module ControllerHelpers
  def current_user
    user_session_info =
      response.request.env['rack.session']['warden.user.user.key']
    return unless user_session_info
    user_id = user_session_info[0][0]
    User.find(user_id)
  end

  def user_signed_in?
    !current_user.nil?
  end

  def mock_user(role = :user, **attrs)
    spy('user', **FactoryGirl.attributes_for(role), **attrs)
  end

  def mock_user_sign_in(user = mock_user)
    allow(request.env['warden']).to receive(:authenticate!).and_return(user)
    # necessary because otherwise ApplicationController#app_setup_check fails
    allow(User).to receive(:count).and_return(1)
    # necessary for permissions to work
    allow(ApplicationController).to receive(:current_user).and_return(user)
    allow(Ability).to receive(:new).and_return(Ability.new(user))
  end
end
