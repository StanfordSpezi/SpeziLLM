
import ObjectBox


// objectbox: entity
class Document {
    var id: Id = 0
    var content: String = ""
    var metadata: [String: String] = [:]
    // objectbox:hnswIndex: dimensions=512
    var embedding: [Float] = []
    
    init() { }
    
    init(id: Id = 0, content: String = "", metadata: [String: String] = [:], embedding: [Float] = []) {
        self.id = id
        self.content = content
        self.metadata = metadata
        self.embedding = embedding
    }
}
