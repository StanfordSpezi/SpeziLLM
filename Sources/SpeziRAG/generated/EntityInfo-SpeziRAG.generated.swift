// Generated using the ObjectBox Swift Generator — https://objectbox.io
// DO NOT EDIT

// swiftlint:disable all
import ObjectBox
import Foundation

// MARK: - Entity metadata

extension _RAGDocument: ObjectBox.Entity {}

extension _RAGDocument: ObjectBox.__EntityRelatable {
    internal typealias EntityType = _RAGDocument

    internal var _id: EntityId<_RAGDocument> {
        return EntityId<_RAGDocument>(self.id.value)
    }
}

extension _RAGDocument: ObjectBox.EntityInspectable {
    internal typealias EntityBindingType = _RAGDocumentBinding

    /// Generated metadata used by ObjectBox to persist the entity.
    internal static var entityInfo = ObjectBox.EntityInfo(name: "_RAGDocument", id: 2)

    internal static var entityBinding = EntityBindingType()

    fileprivate static func buildEntity(modelBuilder: ObjectBox.ModelBuilder) throws {
        let entityBuilder = try modelBuilder.entityBuilder(for: _RAGDocument.self, id: 2, uid: 3474877191370808576)
        try entityBuilder.addProperty(name: "id", type: PropertyType.long, flags: [.id], id: 1, uid: 7202944735452368896)
        try entityBuilder.addProperty(name: "content", type: PropertyType.string, id: 2, uid: 5436555836465158656)
        try entityBuilder.addProperty(name: "alternativeContent", type: PropertyType.string, id: 5, uid: 1787643993702767616)
        try entityBuilder.addProperty(name: "_metadata", type: PropertyType.byteVector, id: 6, uid: 7537841640795151360)
        try entityBuilder.addProperty(name: "embedding", type: PropertyType.floatVector, flags: [.indexed], id: 4, uid: 6620637236891269632, indexId: 2, indexUid: 5439018480120820736)
            .hnswParams(dimensions: 512, neighborsPerNode: nil, indexingSearchCount: nil, flags: nil, distanceType: nil, reparationBacklinkProbability: nil, vectorCacheHintSizeKB: nil)

        try entityBuilder.lastProperty(id: 6, uid: 7537841640795151360)
    }
}

extension _RAGDocument {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { _RAGDocument.id == myId }
    internal static var id: Property<_RAGDocument, Id, Id> { return Property<_RAGDocument, Id, Id>(propertyId: 1, isPrimaryKey: true) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { _RAGDocument.content.startsWith("X") }
    internal static var content: Property<_RAGDocument, String, Void> { return Property<_RAGDocument, String, Void>(propertyId: 2, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { _RAGDocument.alternativeContent.startsWith("X") }
    internal static var alternativeContent: Property<_RAGDocument, String, Void> { return Property<_RAGDocument, String, Void>(propertyId: 5, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { _RAGDocument._metadata > 1234 }
    internal static var _metadata: Property<_RAGDocument, Data, Void> { return Property<_RAGDocument, Data, Void>(propertyId: 6, isPrimaryKey: false) }
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { _RAGDocument.embedding.isNotNil() }
    internal static var embedding: Property<_RAGDocument, HnswIndexPropertyType, Void> { return Property<_RAGDocument, HnswIndexPropertyType, Void>(propertyId: 4, isPrimaryKey: false) }

    fileprivate func __setId(identifier: ObjectBox.Id) {
        self.id = Id(identifier)
    }
}

extension ObjectBox.Property where E == _RAGDocument {
    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .id == myId }

    internal static var id: Property<_RAGDocument, Id, Id> { return Property<_RAGDocument, Id, Id>(propertyId: 1, isPrimaryKey: true) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .content.startsWith("X") }

    internal static var content: Property<_RAGDocument, String, Void> { return Property<_RAGDocument, String, Void>(propertyId: 2, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .alternativeContent.startsWith("X") }

    internal static var alternativeContent: Property<_RAGDocument, String, Void> { return Property<_RAGDocument, String, Void>(propertyId: 5, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { ._metadata > 1234 }

    internal static var _metadata: Property<_RAGDocument, Data, Void> { return Property<_RAGDocument, Data, Void>(propertyId: 6, isPrimaryKey: false) }

    /// Generated entity property information.
    ///
    /// You may want to use this in queries to specify fetch conditions, for example:
    ///
    ///     box.query { .embedding.isNotNil() }

    internal static var embedding: Property<_RAGDocument, HnswIndexPropertyType, Void> { return Property<_RAGDocument, HnswIndexPropertyType, Void>(propertyId: 4, isPrimaryKey: false) }

}


/// Generated service type to handle persisting and reading entity data. Exposed through `_RAGDocument.EntityBindingType`.
internal class _RAGDocumentBinding: ObjectBox.EntityBinding {
    internal typealias EntityType = _RAGDocument
    internal typealias IdType = Id

    internal required init() {}

    internal func generatorBindingVersion() -> Int { 1 }

    internal func setEntityIdUnlessStruct(of entity: EntityType, to entityId: ObjectBox.Id) {
        entity.__setId(identifier: entityId)
    }

    internal func entityId(of entity: EntityType) -> ObjectBox.Id {
        return entity.id.value
    }

    internal func collect(fromEntity entity: EntityType, id: ObjectBox.Id,
                                  propertyCollector: ObjectBox.FlatBufferBuilder, store: ObjectBox.Store) throws {
        let propertyOffset_content = propertyCollector.prepare(string: entity.content)
        let propertyOffset_alternativeContent = propertyCollector.prepare(string: entity.alternativeContent)
        let propertyOffset__metadata = propertyCollector.prepare(bytes: entity._metadata)
        let propertyOffset_embedding = propertyCollector.prepare(values: entity.embedding)

        propertyCollector.collect(id, at: 2 + 2 * 1)
        propertyCollector.collect(dataOffset: propertyOffset_content, at: 2 + 2 * 2)
        propertyCollector.collect(dataOffset: propertyOffset_alternativeContent, at: 2 + 2 * 5)
        propertyCollector.collect(dataOffset: propertyOffset__metadata, at: 2 + 2 * 6)
        propertyCollector.collect(dataOffset: propertyOffset_embedding, at: 2 + 2 * 4)
    }

    internal func createEntity(entityReader: ObjectBox.FlatBufferReader, store: ObjectBox.Store) -> EntityType {
        let entity = _RAGDocument()

        entity.id = entityReader.read(at: 2 + 2 * 1)
        entity.content = entityReader.read(at: 2 + 2 * 2)
        entity.alternativeContent = entityReader.read(at: 2 + 2 * 5)
        entity._metadata = entityReader.read(at: 2 + 2 * 6)
        entity.embedding = entityReader.read(at: 2 + 2 * 4)

        return entity
    }
}


/// Helper function that allows calling Enum(rawValue: value) with a nil value, which will return nil.
fileprivate func optConstruct<T: RawRepresentable>(_ type: T.Type, rawValue: T.RawValue?) -> T? {
    guard let rawValue = rawValue else { return nil }
    return T(rawValue: rawValue)
}

// MARK: - Store setup

fileprivate func cModel() throws -> OpaquePointer {
    let modelBuilder = try ObjectBox.ModelBuilder()
    try _RAGDocument.buildEntity(modelBuilder: modelBuilder)
    modelBuilder.lastEntity(id: 2, uid: 3474877191370808576)
    modelBuilder.lastIndex(id: 2, uid: 5439018480120820736)
    return modelBuilder.finish()
}

extension ObjectBox.Store {
    /// A store with a fully configured model. Created by the code generator with your model's metadata in place.
    ///
    /// # In-memory database
    /// To use a file-less in-memory database, instead of a directory path pass `memory:` 
    /// together with an identifier string:
    /// ```swift
    /// let inMemoryStore = try Store(directoryPath: "memory:test-db")
    /// ```
    ///
    /// - Parameters:
    ///   - directoryPath: The directory path in which ObjectBox places its database files for this store,
    ///     or to use an in-memory database `memory:<identifier>`.
    ///   - maxDbSizeInKByte: Limit of on-disk space for the database files. Default is `1024 * 1024` (1 GiB).
    ///   - fileMode: UNIX-style bit mask used for the database files; default is `0o644`.
    ///     Note: directories become searchable if the "read" or "write" permission is set (e.g. 0640 becomes 0750).
    ///   - maxReaders: The maximum number of readers.
    ///     "Readers" are a finite resource for which we need to define a maximum number upfront.
    ///     The default value is enough for most apps and usually you can ignore it completely.
    ///     However, if you get the maxReadersExceeded error, you should verify your
    ///     threading. For each thread, ObjectBox uses multiple readers. Their number (per thread) depends
    ///     on number of types, relations, and usage patterns. Thus, if you are working with many threads
    ///     (e.g. in a server-like scenario), it can make sense to increase the maximum number of readers.
    ///     Note: The internal default is currently around 120. So when hitting this limit, try values around 200-500.
    ///   - readOnly: Opens the database in read-only mode, i.e. not allowing write transactions.
    ///
    /// - important: This initializer is created by the code generator. If you only see the internal `init(model:...)`
    ///              initializer, trigger code generation by building your project.
    internal convenience init(directoryPath: String, maxDbSizeInKByte: UInt64 = 1024 * 1024,
                            fileMode: UInt32 = 0o644, maxReaders: UInt32 = 0, readOnly: Bool = false) throws {
        try self.init(
            model: try cModel(),
            directory: directoryPath,
            maxDbSizeInKByte: maxDbSizeInKByte,
            fileMode: fileMode,
            maxReaders: maxReaders,
            readOnly: readOnly)
    }
}

// swiftlint:enable all
