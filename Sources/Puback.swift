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

struct PubackPacket {
    var packetId: UInt16
    
    init(packetId: UInt16 = UInt16(random: true)){
        self.packetId = packetId
    }
    init?(data: Data) {
        packetId = UInt16(msb: data[0], lsb: data[1])
    }
}

extension PubackPacket : ControlPacket {

    var description: String {
        return String(ControlCode.puback)
    }

    mutating func write(writer: SocketWriter) throws {

        guard var buffer = Data(capacity: 128) else {
            throw ErrorCodes.errUnknown
        }
        buffer.append(ControlCode.puback.rawValue.data)
        buffer.append(2.data)
        buffer.append(packetId.data)

        do {
            try writer.write(from: buffer)

        } catch {
            throw error

        }
    }

    mutating func unpack(reader: SocketReader) {
    }

    func validate() -> ErrorCodes {
        return .accepted
    }
}
