//
//  Stack.swift
//  j8
//
//  Created by John Heaton on 2/19/15.
//  Copyright (c) 2015 John Heaton. All rights reserved.
//

// FILO
struct Stack<T> {
    private var backing: [T] = []
    
    mutating func push(element: T) {
        backing.append(element)
    }
    
    mutating func pop() -> T? {
        if backing.last != nil {
            return backing.removeLast()
        }
        return nil
    }
    
    mutating func smash() {
        backing.removeAll(keepCapacity: false)
    }
}

