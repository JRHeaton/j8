//
//  main.swift
//  j8
//
//  Created by John Heaton on 2/19/15.
//  Copyright (c) 2015 John Heaton. All rights reserved.
//

import Foundation

var cpu = chip8()
let bytesRead = cpu.loadROM("~/Documents/c8games/PONG2")

for instruction in cpu.disassembleMemoryRange(0x200..<0x200+bytesRead) {
    println(instruction)
}