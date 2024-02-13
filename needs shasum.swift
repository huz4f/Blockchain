import Cocoa

protocol hu{
    func apply(transaction:Transaction)
}

class TransactionTypeSmartContract : hu{
    func apply(transaction:Transaction ){
        
        var fees = 0.0
        
    switch transaction.transactionType{
        case.domestic:
           fees = 0.02
        case.international:
           fees = 0.05
    }
    transaction.fees = transaction.amount * fees
    transaction.amount -= transaction.fees
}
    
    
    
    
}
enum TransactionType: String,Codable{
    case domestic
    case international
}

class Transaction: Codable {
    var from: String
    var to: String
    var amount: Double
    var fees: Double = 0.0
    var transactionType :TransactionType
    
    
    init(from: String, to: String, amount: Double, transactionType:TransactionType) {
        self.transactionType = transactionType
        self.from = from
        self.to = to
        self.amount = amount
    }
}

class Block : Codable {
    var index: Int = 0
    var previousHash: String = ""
    var hash: String!
    var nonce: Int
    
    private (set) var transactions: [Transaction] = [Transaction]()
    
    var key: String {
        get {
            let transactionsData = try! JSONEncoder().encode(self.transactions)
            let transactionsJSONString = String(data: transactionsData, encoding: .utf8)
            return String(self.index) + self.previousHash + String(self.nonce) + (transactionsJSONString ?? "")
        }
    }
    
    func addTransaction(transaction: Transaction) {
        self.transactions.append(transaction)
    }
    
    init() {
        self.nonce = 0
    }
}

class Blockchain : Codable {
    private (set) var blocks: [Block] = [Block]()
    private (set) var smartContracts :[hu] = [TransactionTypeSmartContract()]
    
    
    
    
    init(GenesisBlock: Block) {
        addBlock(GenesisBlock)
    }
    private enum CodingKeys : CodingKey{
        case blocks
    }
    
    func addBlock(_ block: Block) {
        if self.blocks.isEmpty {
            block.previousHash = "0000000000000b0"
            block.hash = generateHash(for: block)
        }
        self.blocks.append(block)
    }
    func getNextBlock(transactions: [Transaction]) -> Block {
        let block = Block()
        transactions.forEach { transaction in
            block.addTransaction(transaction: transaction)
        }

        let previousBlock = getPreviousBlock()
        block.index = self.blocks.count
        block.previousHash = previousBlock.hash
        block.hash = generateHash(for: block)

        return block
    }

    private func getPreviousBlock() -> Block {
        guard let lastBlock = self.blocks.last else {
            // Handle the case when there are no previous blocks
            // For example, you can return a genesis block here
            fatalError("No previous blocks available.")
        }
        return lastBlock
    }

        
        
    
    func generateHash(for block: Block) -> String {
        var hash = block.key.sha1Hash()
        
        //proof of work
        while(!hash.hasPrefix("00")){
            block.nonce += 1
            hash = block.key.sha1Hash()
        }
        return hash
    }
}
extension String{

    func sha1Hash() -> String{
        
        
        let task = Process()
        task.launchPath = "/usr/bin/shasum"
        task.arguments = []
        
        let inputPipe = Pipe()
        
        inputPipe.fileHandleForWriting.write(self.data(using: String.Encoding.utf8)!)
        
        inputPipe.fileHandleForWriting.closeFile()
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardInput = inputPipe
        task.launch()
        
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let hash = String(data: data,encoding: String.Encoding.utf8)!
        return hash.replacingOccurrences(of: " -\n", with: "")
    
    }
}

let GenesisBlock = Block()
let blockchain = Blockchain(GenesisBlock: GenesisBlock)

let transaction = Transaction(from: "mu", to: "hu", amount: 69,transactionType: .domestic)

let block = blockchain.getNextBlock(transactions: [transaction])
blockchain.addBlock(block)

print(blockchain.blocks.count)

let data = try! JSONEncoder().encode(blockchain)
let blockchainJSON = String(data: data, encoding: .utf8)
print(blockchainJSON! )
