/*
 
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 
 */

import UIKit

/// Protocol describing a [Coordinator](http://khanlou.com/2015/10/coordinators-redux/).
/// Coordinators are the objects which control the navigation flow of the application.
/// It helps to isolate and reuse view controllers and pass dependencies down the navigation hierarchy.
protocol Coordinator: class {
    
    /// Starts job of the coordinator.
    func start()
    
    /// Child coordinators to retain. Prevent them from getting deallocated.
    var childCoordinators: [Coordinator] { get set }
    
    /// Stores coordinator to the `childCoordinators` array.
    ///
    /// - Parameter childCoordinator: Child coordinator to store.
    func add(childCoordinator: Coordinator)
    
    /// Remove coordinator from the `childCoordinators` array.
    ///
    /// - Parameter childCoordinator: Child coordinator to remove.
    func remove(childCoordinator: Coordinator)
}

// `Coordinator` default implementation
extension Coordinator {
    
    func add(childCoordinator coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    func remove(childCoordinator: Coordinator) {
        self.childCoordinators = self.childCoordinators.filter { $0 !== childCoordinator }
    }
}
