class BottomNavigationComponent < ViewComponent::Base
  attr_reader :month

  def initialize(month:)
    @month = month.strftime("%Y-%m")
  end

  def link_class(controller, action = nil)
    if helpers.controller_name == controller
      if action.nil? || helpers.action_name == action
        "active"
      end
    end
  end
end
