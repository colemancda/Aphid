//
//  Packet.swift
//  Aphid
//
//  Created by Robert F. Dickerson on 7/10/16.
//
//

import Foundation
import Socket

let PacketNames : [UInt8:String] = [
    1: "CONNECT",
    2: "CONNACK",
    3: "PUBLISH",
    4: "PUBACK",
    5: "PUBREC",
    6: "PUBREL",
    7: "PUBCOMP",
    8: "SUBSCRIBE",
    9: "SUBACK",
    10: "UNSUBSCRIBE",
    11: "UNSUBACK",
    12: "PINGREQ",
    13: "PINGRESP",
    14: "DISCONNECT"
]

enum ControlCode : Byte {
    case connect = 0x01
    case connack = 0x02
    case publish = 0x03
}
let Connect: UInt8  = 1
let Connack  = 2
let Publish  = 3

enum ErrorCodes : Byte {
    case accepted                       = 0x00
    case errRefusedBadProtocolVersion   = 0x01
    case errRefusedIDRejected           = 0x02
    case error                          = 0x03
}
struct Details {
    var qos: Byte
    var messageID: UInt16
}
struct FixedHeader {
    let messageType: ControlCode
    let dup: Bool
    let qos: UInt16
    let retain: Bool
    var remainingLength: UInt8
    
    init(messageType: ControlCode) {
        self.messageType = messageType
        self.dup = true
        self.qos = 0x01
        self.retain = true
        self.remainingLength = 1
    }
    
    func pack() -> NSMutableData {
        let data = NSMutableData()
        data.append(encode(messageType.rawValue << 4 | encodeBit(dup) << 3 | (encodeUInt16(qos)[1] >> 16) << 2 |
                   (encodeUInt16(qos)[1] >> 16) << 1 | encodeBit(dup)))
        data.append(encode(remainingLength))
        return data
    }
}

extension FixedHeader: CustomStringConvertible {
    
    var description: String {
        return "\(messageType): dup: \(dup) qos: \(qos)"
    }
    
}

func newControlPacket(packetType: Byte) -> ControlPacket? {
    switch packetType {
    case Connect:
        return nil//ConnectPacket(fixedHeader: FixedHeader(messageType: .connect), clientIdentifier: "Hello" )
    default:
        return nil
    }
}

func encodeString(str: String) -> NSData {
    let array = NSMutableData()
    let utf = str.data(using: NSUTF8StringEncoding)!
    let fieldLength: [Byte] = encodeUInt16(UInt16(utf.length))
    array.append(encode(fieldLength))
    array.append(utf)

    return array
}

func encodeBit(_ bool: Bool) -> Byte {
    return bool ? 0x01 : 0x00
}

func encodeUInt16(_ value: UInt16) -> [Byte] {
    var bytes: [UInt8] = [0x00, 0x00]
    bytes[0] = UInt8(value >> 8)
    bytes[1] = UInt8(value & 0x00ff)
    return bytes
}

func encodeUInt16(_ value: UInt16) -> NSData {
    var value = value
    return NSData(bytes: &value, length: sizeof(UInt16))
}

public func encode<T>(_ value: T) -> NSData {
    var value = value
    return withUnsafePointer(&value) { p in
        NSData(bytes: p, length: sizeofValue(value))
    }
}

func encodeLength(_ length: Int) -> [Byte] {
    var encLength = [Byte]()
    var length = length

    repeat {
        var digit = Byte(length % 128)
        length /= 128
        if length > 0 {
            digit |= 0x80
        }
        encLength.append(digit)

    } while length != 0

    return encLength
}

func decodebit(_ byte: Byte) -> Bool {
    return byte == 0x01 ? true : false
}
func decodeString(_ reader: SocketReader) -> String {
    let fieldLength = decodeUInt16(reader)
    let field = NSMutableData(capacity: Int(fieldLength))
    do {
       let _ = try reader.read(into: field!)
    } catch {
        
    }
    return String(field)
}
func decodeUInt8(_ reader: SocketReader) -> UInt8 {
    let num = NSMutableData(capacity: 1)
    do {
        let _ = try reader.read(into: num!)
    } catch {
        
    }
    return decode(num!)
}
func decodeUInt16(_ reader: SocketReader) -> UInt16 {
    let uint = NSMutableData(capacity: 2)
    do {
        let _ = try reader.read(into: uint!)
    } catch {
        
    }
    return decode(uint!)
}
public func decode<T>(_ data: NSData) -> T {
    let pointer = UnsafeMutablePointer<T>(allocatingCapacity: sizeof(T))
    data.getBytes(pointer, length: sizeof(T))
    return pointer.move()
}
func decodeLength(_ bytes: [Byte]) -> Int {
    var rLength: UInt32 = 0
    var multiplier: UInt32 = 0
    var b: [Byte] = [0x00]
    while true {
        let digit = b[0]
        rLength |= UInt32(digit & 127) << multiplier
        if (digit & 128) == 0 {
            break
        }
        multiplier += 7
    }
    return Int(rLength)
}
