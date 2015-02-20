//
//  chip8.swift
//  j8
//
//  Created by John Heaton on 2/19/15.
//  Copyright (c) 2015 John Heaton. All rights reserved.
//

import Foundation

struct chip8 {
    
    struct State {
        
        static let baseAddress: UInt16 = 0x200
        static let memSize = 0x1000
        
        var PC: UInt16 = baseAddress
        var I: UInt16 = 0
        var memory = ContiguousArray<UInt8>(count: memSize, repeatedValue: 0)
        var V = [UInt8](count: 0x10, repeatedValue: 0)
        var callStack = Stack<UInt16>()
        var keysDown: [UInt8:Bool] = [:]
        var delayTimer: UInt8 = 0
        var soundTimer: UInt8 = 0
        
        mutating func reset() {
            PC = self.dynamicType.baseAddress
            I = 0
            memory = memory.map { _ in 0 }
            V = V.map { _ in 0 }
            callStack.smash()
            keysDown = [:]
            delayTimer = 0
            soundTimer = 0
        }
    }
    
    enum Instruction: Printable {
        case Unknown
        
        case MachineSubroutine
        case ScreenClear
        case SubroutineReturn
        case Jump(UInt16)
        case Call(UInt16)
        case SkipNextIfVIndexEqual(Int, UInt8)
        case SkipNextIfVIndexNotEqual(Int, UInt8)
        case SkipNextIfVIndicesEqual(Int, Int)
        case SetVIndex(Int, UInt8)
        case AddToVIndex(Int, UInt8)
        case SetVIndexToVIndex(Int, Int)
        case VIndexORByIndex(Int, Int)
        case VIndexANDByIndex(Int, Int)
        case VIndexXORByIndex(Int, Int)
        case VIndexAddIndexAndSetCarry(Int, Int)
        case VIndexSubIndexAndSetBorrow(Int, Int)
        case SetVIndexSHR(Int)
        case SetVIndexToVIndexSub(Int, Int)
        case SetVIndexSHL(Int)
        case SkipNextIfVIndicesNotEqual(Int, Int)
        case StoreMemoryAddress(UInt16)
        case JumpToAddressPlusV0(UInt16)
        case SetVIndexToRandAND(Int, UInt8)
        case DrawSpriteXY(Int, Int, UInt8)
        case SkipNextIfVIndexKeyPressed(Int)
        case SkipNextIfVIndexKeyReleased(Int)
        case SetVIndexToDelayTimer(Int)
        case WaitForKeyPressSetVIndex(Int)
        case SetDelayTimerToVIndex(Int)
        case SetSoundTimerToVIndex(Int)
        case AddVIndexToMemoryAddress(Int)
        case StoreMemoryAddressForVIndexDigit(Int)
        
        func execute(inout state: State) {
            var PCIncrement: UInt16 = 2
            
            switch self {
            case .Unknown: break;
            
            case .MachineSubroutine: break;
            case .ScreenClear: break;
                
            case .SubroutineReturn:
                if let lastAddress = state.callStack.pop() {
                    state.PC = lastAddress
                }
                PCIncrement = 0
                
            case .Jump(let address):
                state.PC = address
                PCIncrement = 0
                
            case .Call(let address):
                state.callStack.push(state.PC)
                state.PC = address
                PCIncrement = 0
                
            case .SkipNextIfVIndexEqual(let index, let value):
                if state.V[index] == value {
                    PCIncrement += 2
                }
                
            case .SkipNextIfVIndexNotEqual(let index, let value):
                if state.V[index] != value {
                    PCIncrement += 2
                }
                
            case .SkipNextIfVIndicesEqual(let first, let second):
                if state.V[first] == state.V[second] {
                    PCIncrement += 2
                }
                
            case .SetVIndex(let index, let value):
                state.V[index] = value
                
            case .AddToVIndex(let index, let value):
                state.V[index] += value
                
            case .SetVIndexToVIndex(let target, let source):
                state.V[target] = state.V[source]
                
            case .VIndexORByIndex(let target, let source):
                state.V[target] |= state.V[source]
                
            case .VIndexANDByIndex(let target, let source):
                state.V[target] &= state.V[source]
                
            case .VIndexXORByIndex(let target, let source):
                state.V[target] ^= state.V[source]
                
            case .VIndexAddIndexAndSetCarry(let target, let source):
                let (result, overflow) = UInt8.addWithOverflow(state.V[target], state.V[source])
                state.V[target] = result
                state.V[0xF] = overflow ? 1 : 0
                
            case .VIndexSubIndexAndSetBorrow(let target, let source):
                let (result, overflow) = UInt8.subtractWithOverflow(state.V[source], state.V[target])
                state.V[target] = result
                state.V[0xF] = overflow ? 0 : 1

            case .SetVIndexSHR(let index):
                state.V[0xF] = state.V[index] & 0x1
                state.V[index] >>= 1
                
            case .SetVIndexToVIndexSub(let target, let source):
                let (result, overflow) = UInt8.subtractWithOverflow(state.V[source], state.V[target])
                state.V[0xF] = overflow ? 0 : 1
                state.V[target] = result
                
            case .SetVIndexSHL(let index):
                state.V[0xF] = state.V[index] & 0x1
                state.V[index] <<= 1
                
            case .SkipNextIfVIndicesNotEqual(let first, let second):
                if state.V[first] != state.V[second] {
                    PCIncrement += 2
                }
                
            case .StoreMemoryAddress(let address):
                state.I = address
                
            case .JumpToAddressPlusV0(let address):
                state.PC = address + UInt16(state.V[0])
                PCIncrement = 0
                
            case .SetVIndexToRandAND(let index, let mask):
                state.V[index] = UInt8(arc4random() % UInt32(UInt8.max)) & mask
                
            case .DrawSpriteXY(let x, let y, let length): break;
                
            case .SkipNextIfVIndexKeyPressed(let index):
                if state.keysDown[state.V[index]] == true {
                    PCIncrement += 2
                }
                
            case .SkipNextIfVIndexKeyReleased(let index):
                if state.keysDown[state.V[index]] == false {
                    PCIncrement += 2
                }

            case .SetVIndexToDelayTimer(let index):
                state.V[Int(index)] = state.delayTimer
                
            case .WaitForKeyPressSetVIndex(let index): break;
                
            case .SetDelayTimerToVIndex(let index):
                state.delayTimer = state.V[index]
                
            case .SetSoundTimerToVIndex(let index):
                state.soundTimer = state.V[index]
                
            case .AddVIndexToMemoryAddress(let index):
                state.I += UInt16(state.V[index])
                
            case .StoreMemoryAddressForVIndexDigit(let index): break;
                
            }
            
            state.PC += PCIncrement
        }
        
        var description: String {
            func hex(value: UInt16) -> String {
                return NSString(format: "%02x", value) as! String
            }
            let hex8: UInt8 -> String = { hex(UInt16($0)) }
            
            switch self {
            case .ScreenClear:
                return "cls"
            case .SubroutineReturn:
                return "ret"
            case .Jump(let address):
                return "jmp \(hex(address))"
            case .Call(let address):
                return "call \(hex(address))"
            case .SkipNextIfVIndexEqual(let index, let value):
                return "se v\(index), \(hex8(value))"
            case .SkipNextIfVIndexNotEqual(let index, let value):
                return "sne v\(index), \(hex8(value))"
            case .SkipNextIfVIndicesEqual(let first, let second):
                return "se v\(first), v\(second)"
            case .SetVIndex(let index, let value):
                return "ld v\(index), \(hex8(value))"
            case .AddToVIndex(let index, let value):
                return "add v\(index), \(hex8(value))"
            case .SetVIndexToVIndex(let target, let source):
                return "ld v\(target), v\(source)"
            case .VIndexORByIndex(let target, let source):
                return "or v\(target), v\(source)"
            case .VIndexANDByIndex(let target, let source):
                return "and v\(target), v\(source)"
            case .VIndexXORByIndex(let target, let source):
                return "xor v\(target), v\(source)"
            case .VIndexAddIndexAndSetCarry(let target, let source):
                return "add v\(target), v\(source)"
            case .VIndexSubIndexAndSetBorrow(let target, let source):
                return "sub v\(target), v\(source)"
            case .SetVIndexSHR(let index):
                return "shr v\(index)"
            case .SetVIndexToVIndexSub(let target, let source):
                return "subn v\(target), v\(source)"
            case .SetVIndexSHL(let index):
                return "shl v\(index)"
            case .SkipNextIfVIndicesNotEqual(let target, let source):
                return "sne v\(target), v\(source)"
            case .StoreMemoryAddress(let address):
                return "ld I, \(hex(address))"
            case .JumpToAddressPlusV0(let address):
                return "jmp v0, \(hex(address))"
            case .SetVIndexToRandAND(let index, let value):
                return "rnd v\(index), \(hex8(value))"
            case .DrawSpriteXY(let x, let y, let length):
                return "drw v\(x), v\(y), \(hex8(length))"
            case .SkipNextIfVIndexKeyPressed(let index):
                return "skp v\(index)"
            case .SkipNextIfVIndexKeyReleased(let index):
                return "skp v\(index)"
            case .SetVIndexToDelayTimer(let index):
                return "sknp v\(index)"
            case .WaitForKeyPressSetVIndex(let index):
                return "ld v\(index), [key]"
            case .SetDelayTimerToVIndex(let index):
                return "ld [dt], v\(index)"
            case .SetSoundTimerToVIndex(let index):
                return "ld [st], v\(index)"
            case .AddVIndexToMemoryAddress(let index):
                return "add I, v\(index)"
            case .StoreMemoryAddressForVIndexDigit(let index):
                return "ld F, v\(index)"
                
            case .Unknown: fallthrough
            default:
                return "<Unknown Instruction>"
            }
        }
        
        init(_ byte1: UInt8, _ byte2: UInt8) {
            let idNibble = (byte1 & 0xf0) >> 4
            
            let address = (UInt16(byte1) << 8) | UInt16(byte2)
            let vIndices = (Int(byte1 & 0x0f), Int(byte2 & 0xf0))
            
            switch idNibble {
            case 0:
                switch byte2 {
                case 0xe0: self = .ScreenClear
                case 0xee: self = .SubroutineReturn
                default: self = .MachineSubroutine
                }

            case 1: self = .Jump(address)
            case 2: self = .Call(address)
            case 3: self = .SkipNextIfVIndexEqual(vIndices.0, byte2)
            case 4: self = .SkipNextIfVIndexNotEqual(vIndices.0, byte2)
            case 5: self = .SkipNextIfVIndicesEqual(vIndices)
            case 6: self = .SetVIndex(vIndices.0, byte2)
            case 7: self = .AddToVIndex(vIndices.0, byte2)
            case 8:
                switch byte2 & 0x0f {
                case 0: self = .SetVIndexToVIndex(vIndices)
                case 1: self = .VIndexORByIndex(vIndices)
                case 2: self = .VIndexANDByIndex(vIndices)
                case 3: self = .VIndexXORByIndex(vIndices)
                case 4: self = .VIndexAddIndexAndSetCarry(vIndices)
                case 5: self = .VIndexSubIndexAndSetBorrow(vIndices)
                case 6: self = .SetVIndexSHR(vIndices.0)
                case 7: self = .SetVIndexToVIndexSub(vIndices)
                case 0xe: self = .SetVIndexSHL(vIndices.0)
                default: self = .Unknown
                }
            case 9: self = .SkipNextIfVIndicesNotEqual(vIndices)
            case 0xa: self = .StoreMemoryAddress(address)
            case 0xb: self = .JumpToAddressPlusV0(address)
            case 0xc: self = .SetVIndexToRandAND(vIndices.0, byte2)
            case 0xd: self = .DrawSpriteXY(vIndices.0, vIndices.1, byte2 & 0x0f)
            case 0xe:
                switch byte2 {
                case 0x9e: self = .SkipNextIfVIndexKeyPressed(vIndices.0)
                case 0xa1: self = .SkipNextIfVIndexKeyReleased(vIndices.0)
                default: self = .Unknown
                }
            case 0xf:
                switch byte2 {
                case 0x07: self = .SetVIndexToDelayTimer(vIndices.0)
                case 0x0a: self = .WaitForKeyPressSetVIndex(vIndices.0)
                case 0x15: self = .SetDelayTimerToVIndex(vIndices.0)
                case 0x18: self = .SetSoundTimerToVIndex(vIndices.0)
                case 0x1e: self = .AddVIndexToMemoryAddress(vIndices.0)
                case 0x29: self = .StoreMemoryAddressForVIndexDigit(vIndices.0)
                default: self = .Unknown
                }
                
            default: self = .Unknown
            }
        }
    }
    
    var state = State()
    
    mutating func execute() {
        
    }
    
    mutating func loadMemory(data: UnsafePointer<Void>, length: UInt16, address: UInt16 = State.baseAddress) {
        state.memory.withUnsafeMutableBufferPointer { (ptr) -> () in
            memcpy(ptr.baseAddress, data, UInt(length)); ()
        }
    }
    
    func disassembleMemoryRange(range: Range<UInt16>) -> [Instruction] {
        var i = Int(range.startIndex)
        var ret = [Instruction]()
        while i < Int(range.endIndex) {
            ret.append(Instruction(state.memory[i], state.memory[i+1]))
            
            i += 2
        }
        return ret
    }
}