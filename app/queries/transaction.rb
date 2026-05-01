class Transaction
  Result = Data.define(:transaction)

  def self.call(tx_id:)
    tx = Transactions.call(include_archived: true).transactions.find { |t| t.id == tx_id }
    raise NotFoundError, "Transaction not found." unless tx
    Result.new(transaction: tx)
  end
end
