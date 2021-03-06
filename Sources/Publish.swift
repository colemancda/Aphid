/**
 Copyright IBM Corporation 2016

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import Socket

struct PublishPacket {
    var controlByte: UInt8
    
    var qos: QosType

    var topic: String
    var identifier = UInt16(random: true)
    var message: String

    init(topic: String, message: String = "", dup: Bool = false, qos: QosType = .atLeastOnce, willRetain: Bool = false) {

        controlByte = ControlCode.publish.rawValue | dup.toByte << 3 | qos.rawValue << 1 | willRetain.toByte

        self.qos = qos
        self.topic = topic
        self.message = message
        
    }

    init?(header: Byte, bodyLength: Int, data: Data) {
        var data = data

        self.controlByte = header
        self.qos = QosType(rawValue: controlByte & UInt8(0x08))!
        
        topic = data.decodeString

        if qos.rawValue > 0 {
            identifier = data.decodeUInt16

        }

        message = data.decodeSDataString

    }
}

extension PublishPacket: ControlPacket {

    var description: String {
        return String(ControlCode.publish)
    }

    mutating func write(writer: SocketWriter) throws {
        guard var packet = Data(capacity: 512),
              var buffer = Data(capacity: 512) else {
            throw ErrorCodes.errUnknown
        }
        
        buffer.append(topic.data)

        if qos.rawValue > 0 {
            buffer.append(identifier.data)
        }
        
        buffer.append(message.sData)

        packet.append(controlByte.data)

        for byte in buffer.count.toBytes {
            packet.append(byte.data)
        }

        packet.append(buffer)

        do {
            try writer.write(from: packet)

        } catch {
            throw NSError()

        }
    }

    mutating func unpack(reader: SocketReader) {
    }

    func validate() -> ErrorCodes {
        return .accepted
    }
}
