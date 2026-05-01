class Applicant
  Result = Data.define(:application)

  def self.call(applicant_id:)
    application = Applications.call.applications.find { |a| a.id == applicant_id }
    Result.new(application: application)
  end
end
