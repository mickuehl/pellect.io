module ApplicationHelper

  def application_name
		Rails.application.secrets.app_name
  end
  
  def user_has_admin_role?
    current_user.has_role? :admin
  end
  
  def user_is_confirmed? (user)
    not (user.confirmed_at == nil)
  end
  
  def user_is_locked? (user)
    false
  end
 
end
