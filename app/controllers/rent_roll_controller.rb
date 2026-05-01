class RentRollController < ApplicationController
  def show
    @result = RentRoll.call
  end
end
