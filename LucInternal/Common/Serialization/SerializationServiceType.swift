/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import Foundation

protocol SerializationServiceType {
    func deserialize<T: Decodable>(_ data: Data) throws -> T
    func serialize<T: Encodable>(_ object: T) throws -> Data
}
