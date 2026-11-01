# frozen_string_literal: true

class BottomNavigationComponent < ViewComponent::Base
  attr_reader :month

  def initialize(month:)
    @month = month.strftime("%Y-%m")
  end

  def link_class(controller)
    helpers.controller_name == controller ? "active" : nil
  end
end
