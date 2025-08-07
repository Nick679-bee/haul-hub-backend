class CustomFailureApp < Devise::FailureApp
  def store_location!
    # Do nothing - override the default behavior that tries to store in session
  end
end