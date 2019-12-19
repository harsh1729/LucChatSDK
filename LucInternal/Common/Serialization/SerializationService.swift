/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

final class SerializationService: SerializationServiceType {
    
    // MARK: - Properties
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // MARK: - Public
    
    func deserialize<T: Decodable>(_ data: Data) throws -> T {
        return try decoder.decode(T.self, from: data)
    }
    
    func serialize<T: Encodable>(_ object: T) throws -> Data {
        return try encoder.encode(object)
    }
}
