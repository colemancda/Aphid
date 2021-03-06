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

struct ConnackPacket {
    var flags: Byte = 0x00
    var responseCode: Byte = 0x00
    
    init(){}

    init(data: Data) {
        var data = data
        self.flags = data.decodeUInt8
        self.responseCode = data.decodeUInt8
    }

}

extension ConnackPacket: ControlPacket {

    var description: String {
        return String(ControlCode.connack)
    }

    mutating func write(writer: SocketWriter) throws {

        guard var buffer = Data(capacity: 128) else {
            throw NSError()
        }
        
        buffer.append(ControlCode.connack.rawValue.data)
        buffer.append(UInt8(2).data)
        buffer.append(flags.data)
        buffer.append(UInt8(responseCode).data)

        do {
            try writer.write(from: buffer)

        } catch {
            throw error

        }
    }

    mutating func unpack(reader: SocketReader) {
    }

    func validate() -> ErrorCodes {

        switch responseCode {
        case 0: return .accepted
        case 1: return .errRefusedBadProtocolVersion
        case 2: return .errRefusedIDRejected
        case 3: return .errServerUnavailable
        case 4: return .errBadUsernameOrPassword
        case 5: return .errNotAuthorize
        default: return .errUnknown
        }
    }
}
