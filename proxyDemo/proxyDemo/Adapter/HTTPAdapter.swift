//
//  HTTPAdapter.swift
//  proxyDemo
//
//  Created by 方冬冬 on 2021/1/20.
//

import Foundation

protocol AdapterDelegate {
    func didBecomeReadyToForwardWith(socket:HTTPAdapter)
    func didRead(data:Data,from:HTTPAdapter)
    func didWrite(data:Data,from:HTTPAdapter)
    func readData()
}


class HTTPAdapter:NSObject, GCDAsyncSocketDelegate {

    enum HTTPAdapterStatus {
        case invalid,
        connecting,
        readingResponse,
        forwarding,
        stopped
    }

    /// The host domain of the HTTP proxy.
    let serverHost: String

    /// The port of the HTTP proxy.
    let serverPort: Int

    /// The authentication information for the HTTP proxy.
    let auth: HTTPAuthentication?

    /// Whether the connection to the proxy should be secured or not.
    var secured: Bool

    var internalStatus: HTTPAdapterStatus = .invalid

    open var session: ConnectSession!

    var adapterSocket: GCDAsyncSocket!

    var delegate:AdapterDelegate?

    public init(serverHost: String, serverPort: Int, auth: HTTPAuthentication?) {
        self.serverHost = serverHost
        self.serverPort = serverPort
        self.auth = auth
        adapterSocket = GCDAsyncSocket.init(delegate: nil, delegateQueue: DispatchQueue.main)
        secured = false
    }

    public func openSocketWith(session: ConnectSession) {

//        guard !isCancelled else {
//            return
//        }

        do {
            internalStatus = .connecting
            adapterSocket.delegate = self
            print("ip: \(session.ipAddress) \r\nport:\(serverPort)")
            try adapterSocket.connect(toHost: session.ipAddress, onPort: UInt16(serverPort), withTimeout: -1)
            if secured {
                startTLSWith(settings: nil)
            }
        } catch {}
        self.session = session
    }

    func startTLSWith(settings: [AnyHashable: Any]!) {
        if let settings = settings as? [String: NSObject] {
            adapterSocket.startTLS(ensureSendPeerName(tlsSettings: settings))
        } else {
            adapterSocket.startTLS(ensureSendPeerName(tlsSettings: nil))
        }
    }

    private func ensureSendPeerName(tlsSettings: [String: NSObject]? = nil) -> [String: NSObject] {
        var setting = tlsSettings ?? [:]
        guard setting[kCFStreamSSLPeerName as String] == nil else {
            return setting
        }

        setting[kCFStreamSSLPeerName as String] = serverHost as NSString
        return setting
    }

    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        guard let url = URL(string: "\(session.host):\(session.port)") else {
            return
        }
        let message = CFHTTPMessageCreateRequest(kCFAllocatorDefault, "CONNECT" as CFString, url as CFURL, kCFHTTPVersion1_1).takeRetainedValue()
        if let authData = auth {
            CFHTTPMessageSetHeaderFieldValue(message, "Proxy-Authorization" as CFString, authData.authString() as CFString?)
        }
        CFHTTPMessageSetHeaderFieldValue(message, "Host" as CFString, "\(session.host):\(session.port)" as CFString?)
        CFHTTPMessageSetHeaderFieldValue(message, "Content-Length" as CFString, "0" as CFString?)

        guard let requestData = CFHTTPMessageCopySerializedMessage(message)?.takeRetainedValue() else {
            return
        }

        internalStatus = .readingResponse
//        adapterSocket.write(data: requestData as Data)
        adapterSocket.write(requestData as Data, withTimeout: -1, tag: 0)
        adapterSocket.readData(to: Utils.HTTPData.DoubleCRLF, withTimeout: -1, tag: 1)
//        socket.readDataTo(data: Utils.HTTPData.DoubleCRLF)
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        switch internalStatus {
        case .readingResponse:
            internalStatus = .forwarding
            delegate?.didBecomeReadyToForwardWith(socket: self)

        case .forwarding:
            delegate?.didRead(data: data, from: self)
        default:
            return
        }
    }

    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        if internalStatus == .forwarding {
            delegate?.readData()
        }
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("adapter err:\(err?.localizedDescription)")
    }



//    override public func didConnectWith(socket: RawTCPSocketProtocol) {
//        super.didConnectWith(socket: socket)
//
//        guard let url = URL(string: "\(session.host):\(session.port)") else {
//            observer?.signal(.errorOccured(HTTPAdapterError.invalidURL, on: self))
//            disconnect()
//            return
//        }
//        let message = CFHTTPMessageCreateRequest(kCFAllocatorDefault, "CONNECT" as CFString, url as CFURL, kCFHTTPVersion1_1).takeRetainedValue()
//        if let authData = auth {
//            CFHTTPMessageSetHeaderFieldValue(message, "Proxy-Authorization" as CFString, authData.authString() as CFString?)
//        }
//        CFHTTPMessageSetHeaderFieldValue(message, "Host" as CFString, "\(session.host):\(session.port)" as CFString?)
//        CFHTTPMessageSetHeaderFieldValue(message, "Content-Length" as CFString, "0" as CFString?)
//
//        guard let requestData = CFHTTPMessageCopySerializedMessage(message)?.takeRetainedValue() else {
//            observer?.signal(.errorOccured(HTTPAdapterError.serailizationFailure, on: self))
//            disconnect()
//            return
//        }
//
//        internalStatus = .readingResponse
//        write(data: requestData as Data)
//        socket.readDataTo(data: Utils.HTTPData.DoubleCRLF)
//    }
//
//    override public func didRead(data: Data, from socket: RawTCPSocketProtocol) {
//        super.didRead(data: data, from: socket)
//
//        switch internalStatus {
//        case .readingResponse:
//            internalStatus = .forwarding
//            observer?.signal(.readyForForward(self))
//            delegate?.didBecomeReadyToForwardWith(socket: self)
//        case .forwarding:
//            observer?.signal(.readData(data, on: self))
//            delegate?.didRead(data: data, from: self)
//        default:
//            return
//        }
//    }
//
//    override public func didWrite(data: Data?, by socket: RawTCPSocketProtocol) {
//        super.didWrite(data: data, by: socket)
//        if internalStatus == .forwarding {
//            observer?.signal(.wroteData(data, on: self))
//            delegate?.didWrite(data: data, by: self)
//        }
//    }

}
