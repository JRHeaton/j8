//
//  main.swift
//  j8
//
//  Created by John Heaton on 2/19/15.
//  Copyright (c) 2015 John Heaton. All rights reserved.
//

import Foundation

var cpu = chip8()

let data = NSData(contentsOfFile: "/Users/j/Downloads/Chip-8 Pack/Chip-8 Games/15 Puzzle [Roger Ivie].ch8")
cpu.loadMemory(data!.bytes, length: UInt16(data!.length))

for instruction in cpu.disassembleMemoryRange(0x200..<(0x200 + UInt16(data!.length))) {
    println(instruction)
}