//
//  NVASocket.swift
//  BilibiliLive
//
//  Created by yicheng on 2022/11/25.
//

import Foundation
import Swifter
import SwiftyJSON

enum NVAError: Error {
    case decode
}

public func nvasocket(
    uuid: String,
    didConnect: ((NVASession) -> Void)? = nil,
    didDisconnect: ((NVASession) -> Void)? = nil,
    processor: ((NVASession, NVASession.NVAFrame) -> Void)? = nil
) -> ((HttpRequest) -> HttpResponse) {
    return { request in
        guard request.method == "SETUP", let connectSession = request.headers["session"] else {
            return .badRequest(.text("No setup"))
        }

        let protocolSessionClosure: ((Socket) -> Void) = { socket in
            let session = NVASession(socket)
            func read() throws {
                while true {
                    let frame = try session.readFrame()
                    if frame.paramCount == 0 {
                        print("get pong")
                    } else {
                        if frame.isCommand {
                            processor?(session, frame)
                        }
                    }
                }
            }
            didConnect?(session)
            do {
                try read()
            } catch let err {
                Logger.warn("\(err)")
            }
            didDisconnect?(session)
        }
        let header = ["Session": connectSession,
                      "NvaVersion": "1",
                      "Connection": "Keep-Alive",
                      "UUID": uuid,
                      "User-Agent": "Linux/3.0.0 UPnP/1.0 Platinum/1.0.5.13"]
        return HttpResponse.rawProtocol(200, "OK", header, "NVA", protocolSessionClosure)
    }
}

public class NVASession: Hashable, Equatable {
    public static func == (lhs: NVASession, rhs: NVASession) -> Bool {
        lhs.socket == rhs.socket
    }

    var timer: Timer?

    var currentVersion = 1
    lazy var socketQueue = DispatchQueue(label: "nva-socket")

    public struct NVAFrame {
        // e0
        var isCommand = false
        var paramCount: Int = 0 // 2 or 3  0 menans ping
        var number: UInt32 = 0
        var version = 0x01
        var commandLength: UInt8 = 0
        var command: String = ""
        var actionLength: UInt8 = 0
        var action: String = ""
        var bodyLength: UInt32 = 0
        var body: String = ""
    }

    func readFrame() throws -> NVAFrame {
        var frame = NVAFrame()
        let fst = try socket.read()
        frame.isCommand = fst == 0xe0
        frame.paramCount = try Int(socket.read())

        let versions = try socket.read(length: 4)
        let version = Data(versions).reversed().withUnsafeBytes({ $0.load(as: UInt32.self) })
        frame.version = Int(version)
        let frameVersion = frame.version
        // Keep all currentVersion access on socketQueue so it stays serialized with the send path.
        socketQueue.async { [weak self] in self?.currentVersion = frameVersion }

        if frame.paramCount == 0 {
            // is ping
            return frame
        }
        _ = try socket.read() // 0x01
        frame.commandLength = try socket.read()
        // Payloads come straight off the casting client socket; a non-UTF8/truncated payload must throw
        // (caught by the read loop as a clean disconnect), not trap and kill the connection thread.
        guard let command = try String(bytes: socket.read(length: Int(frame.commandLength)).reversed(), encoding: .utf8) else { throw NVAError.decode }
        frame.command = command

        if fst != 0xe0 || frame.paramCount == 1 {
            Logger.debug("reply: \(frame.command)")
            return frame
        }

        frame.actionLength = try socket.read()
        guard let action = try String(bytes: socket.read(length: Int(frame.actionLength)), encoding: .utf8) else { throw NVAError.decode }
        frame.action = action

        if frame.paramCount == 3 {
            let p3L = try socket.read(length: 4)
            let part3Length = Data(p3L).reversed().withUnsafeBytes({ $0.load(as: UInt32.self) })
            frame.bodyLength = part3Length
            guard let body = try String(bytes: socket.read(length: Int(frame.bodyLength)), encoding: .utf8) else { throw NVAError.decode }
            frame.body = body
        }

        return frame
    }

    func writeData(_ data: Data) {
        socketQueue.async { [weak self] in
            try? self?.socket.writeData(data)
        }
    }

    /// Bumps `currentVersion` and writes the built frame, all on socketQueue, so the version assigned to
    /// each frame matches the order it is actually sent in (locking the counter alone wouldn't guarantee that).
    private func send(_ makeFrame: @escaping (UInt32) -> Data) {
        socketQueue.async { [weak self] in
            guard let self else { return }
            self.currentVersion += 1
            let data = makeFrame(UInt32(self.currentVersion))
            try? self.socket.writeData(data)
        }
    }

    func sendReply(content: [String: Any]) {
        guard let str = try? JSON(content).rawData() else { return }
        send { version in
            var arr: [UInt8] = [0xc0, 0x01]
            arr.append(contentsOf: version.toUInt8s)
            arr.append(contentsOf: UInt32(str.count).toUInt8s)
            var data = Data(arr)
            data.append(str)
            return data
        }
    }

    func sendPing() {
        send { version in
            var arr: [UInt8] = [0xe4, 0x00]
            arr.append(contentsOf: version.toUInt8s)
            return Data(arr)
        }
    }

    func sendCommand(action: String, content: [String: Any]) {
        guard let str = try? JSON(content).rawData(),
              let command = "Command".data(using: .ascii),
              let actionData = action.data(using: .ascii)
        else { return }
        send { version in
            var arr = Data([0xe0, 0x03])
            arr.append(contentsOf: version.toUInt8s)
            arr.append(0x01)
            arr.append(UInt8(command.count))
            arr.append(command)
            arr.append(UInt8(actionData.count))
            arr.append(actionData)
            arr.append(contentsOf: UInt32(str.count).toUInt8s)
            arr.append(str)
            return arr
        }
    }

    func sendEmpty() {
        send { version in
            var arr: [UInt8] = [0xc0, 0x00]
            arr.append(contentsOf: version.toUInt8s)
            return Data(arr)
        }
    }

    let socket: Socket

    init(_ socket: Socket) {
        self.socket = socket
//        DispatchQueue.main.async {
//            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
//                print("send ping")
//                self?.sendPing()
//            }
//        }
    }

    deinit {
        timer?.invalidate()
        socket.close()
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(socket)
    }
}
