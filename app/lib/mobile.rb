module Mobile
  def self.normalize(input)
    return nil if input.blank?
    digits = input.to_s.gsub(/\D/, "")
    case digits.length
    when 10 then "+1#{digits}"
    when 11 then digits.start_with?("1") ? "+#{digits}" : nil
    else nil
    end
  end
end
