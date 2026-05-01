class Taxes
  TaxView = Data.define(:id, :name, :rate_bp, :added_at, :updated_at) do
    def rate_percent
      rate_bp.to_i / 100.0
    end

    def label
      "#{name} (#{format("%g", rate_percent)}%)"
    end
  end

  Result = Data.define(:taxes)

  def self.call
    added = Rails.configuration.event_store.read
      .stream("Taxes")
      .of_type([ TaxAdded ])
      .to_a

    updates = Rails.configuration.event_store.read
      .of_type([ TaxUpdated ])
      .to_a
      .group_by { |e| e.data[:tax_id] }

    taxes = added.map do |e|
      latest = updates[e.data[:tax_id]]&.last
      data = latest ? latest.data : e.data
      TaxView.new(
        id: e.data[:tax_id],
        name: data[:name].to_s,
        rate_bp: data[:rate_bp].to_i,
        added_at: e.data[:added_at],
        updated_at: latest ? latest.data[:updated_at] : nil
      )
    end

    Result.new(taxes: taxes.sort_by { |t| t.name.to_s.downcase })
  end
end
