//
//  HTTPProxyGCDAsyncSocket.swift
//  proxyDemo
//
//  Created by 方冬冬 on 2021/1/18.
//

import Foundation

class HTTPProxyGCDAsyncSocket: NSObject,GCDAsyncSocketDelegate, AdapterDelegate {


    enum HTTPProxyReadStatus: CustomStringConvertible {
        case invalid,
        readingFirstHeader,
        pendingFirstHeader,
        readingHeader,
        readingContent,
        stopped

        var description: String {
            switch self {
            case .invalid:
                return "invalid"
            case .readingFirstHeader:
                return "reading first header"
            case .pendingFirstHeader:
                return "waiting to send first header"
            case .readingHeader:
                return "reading header (forwarding)"
            case .readingContent:
                return "reading content (forwarding)"
            case .stopped:
                return "stopped"
            }
        }
    }

    enum HTTPProxyWriteStatus: CustomStringConvertible {
        case invalid,
        sendingConnectResponse,
        forwarding,
        stopped

        var description: String {
            switch self {
            case .invalid:
                return "invalid"
            case .sendingConnectResponse:
                return "sending response header for CONNECT"
            case .forwarding:
                return "waiting to begin forwarding data"
            case .stopped:
                return "stopped"
            }
        }
    }

    /// The remote host to connect to.
    public var destinationHost: String!

    /// The remote port to connect to.
    public var destinationPort: Int!

    public var isConnectCommand = false
    private let scanner: HTTPStreamScanner = HTTPStreamScanner()

    private var readStatus: HTTPProxyReadStatus = .invalid
    private var writeStatus: HTTPProxyWriteStatus = .invalid
    private var currentHeader: HTTPHeader!

    public var socket: GCDAsyncSocket!
    public var adapter: HTTPAdapter!


    init(socket:GCDAsyncSocket) {
        self.socket = socket
    }

    func openSocket() {
        self.socket.delegate = self
        readStatus = .readingFirstHeader
        socket.readData(to: Utils.HTTPData.DoubleCRLF, withTimeout: -1, tag: 1)
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("error descrtion:\(String(describing: err?.localizedDescription))")
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let str = String.init(data: data, encoding: String.Encoding.utf8)
        print("HTTPProxyGCDAsyncSocket Read Data:\(str)")

        let result: HTTPStreamScanner.Result
        do {
            result = try scanner.input(data)
        } catch let error {
//            disconnect(becauseOf: error)
            return
        }

        switch (readStatus, result) {
        case (.readingFirstHeader, .header(let header)):
            currentHeader = header
            currentHeader.removeProxyHeader()
            currentHeader.rewriteToRelativePath()

            destinationHost = currentHeader.host
            destinationPort = currentHeader.port
            isConnectCommand = currentHeader.isConnect

            if !isConnectCommand {
                readStatus = .pendingFirstHeader
            } else {
                readStatus = .readingContent
            }

            let session = ConnectSession(host: destinationHost!, port: destinationPort!)
//            delegate?.didReceive(session: session!, from: self)
            didReceive(session: session!)
        case (.readingHeader, .header(let header)):
            currentHeader = header
            currentHeader.removeProxyHeader()
            currentHeader.rewriteToRelativePath()

//            delegate?.didRead(data: currentHeader.toData(), from: self)
        case (.readingContent, .content(let content)): break
//            delegate?.didRead(data: content, from: self)
        default:
            return
        }
    }

    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {

    }

    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {

    }

    func didReceive(session:ConnectSession) {
        if !session.isIP() {
            _ = Resolver.resolve(hostname: session.host, timeout: Opt.DNSTimeout) { [weak self] resolver, err in
                if err != nil {
                    session.ipAddress = ""
                } else {
                    session.ipAddress = (resolver?.ipv4Result.first)!
                }
                self?.openAdapter(for: session)
            }
        } else {
            session.ipAddress = session.host
            openAdapter(for: session)
        }
    }

    fileprivate func openAdapter(for session: ConnectSession) {
        adapter = HTTPAdapter.init(serverHost: session.host, serverPort: session.port, auth: nil)
        adapter.delegate = self
        adapter.openSocketWith(session: session)
    }

    func didBecomeReadyToForwardWith(socket: HTTPAdapter) {
        if isConnectCommand {
            writeStatus = .sendingConnectResponse
//            socket.write(data: Utils.HTTPData.ConnectSuccessResponse)
            self.socket.write(Utils.HTTPData.ConnectSuccessResponse, withTimeout: -1, tag: 1)
        } else {
            writeStatus = .forwarding
            self.readData()
            self.adapter.adapterSocket.readData(withTimeout: -1, tag: 1)
        }
    }

    func didRead(data: Data, from: HTTPAdapter) {

    }

    func didWrite(data: Data, from: HTTPAdapter) {

    }

    func readData() {

    }

}
