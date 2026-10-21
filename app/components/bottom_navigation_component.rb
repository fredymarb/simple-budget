# frozen_string_literal: true

class BottomNavigationComponent < ViewComponent::Base
  attr_reader :month

  def initialize(month:)
    @month = month.strftime("%Y-%m")
  end
end
