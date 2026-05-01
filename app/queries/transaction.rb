class Transaction
  Result = Data.define(:transaction)

  def self.call(tx_id:)
    tx = Transactions.call.transactions.find { |t| t.id == tx_id }
    Result.new(transaction: tx)
  end
end
