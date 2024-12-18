
import ObjectBox


// objectbox: entity
class Document {
    var id: Id = 0
    var content: String = ""
    var metadata: [String: String] = [:]
    
    
    init() { }
    
    init(metadata: [String: String]) {
        self.metadata = metadata
    }
}




//class Person {
//    var id: Id = 0
//    var firstName: String = ""
//    var lastName: String = ""
//    // objectbox:hnswIndex: dimensions=2
//    var location: [Float]?
//    
//    init() { }
//    
//    init(id: Id = 0, firstName: String, lastName: String, location: [Float]?) {
//        self.id = id
//        self.firstName = firstName
//        self.lastName = lastName
//        self.location = location
//    }
//    
//    // objectbox: transient
//    var fullName: String {
//        firstName + " " + lastName
//    }
//    
//    // objectbox: transient
//    var distance: Double? = nil
//
//}
