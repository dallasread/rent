class UserDashboard
  Result = Data.define(:mobile)

  def self.call(mobile:)
    Result.new(mobile: mobile)
  end
end
