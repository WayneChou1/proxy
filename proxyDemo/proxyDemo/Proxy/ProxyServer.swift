//
//  ProxyServer.swift
//  proxyDemo
//
//  Created by 方冬冬 on 2021/1/18.
//

import Foundation
import CocoaAsyncSocket

class ProxyServer: NSObject,GCDAsyncSocketDelegate {

    var listenSocket: GCDAsyncSocket!
    var proxy: Proxy!
    var proxySocket: HTTPProxyGCDAsyncSocket!


    init(proxy:Proxy) {
        super.init()
        self.proxy = proxy
    }

    func start() throws {
        listenSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main, socketQueue: DispatchQueue.main)
        try listenSocket.accept(onInterface: "127.0.0.1", port: self.proxy.port.value)
    }

    func stop() {
        listenSocket?.setDelegate(nil, delegateQueue: nil)
        listenSocket?.disconnect()
        listenSocket = nil
    }

    func socket(_ sock: GCDAsyncSocket, didConnectTo url: URL) {
//        sock.startTLS(<#T##tlsSettings: [String : NSObject]?##[String : NSObject]?#>)
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("err:\(err?.localizedDescription)")
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {

    }

    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {

    }

    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        print("url:\(String(describing: newSocket.localHost))")
        proxySocket = HTTPProxyGCDAsyncSocket.init(socket: newSocket)
        proxySocket.openSocket()
//        sock.readDataTo(data: "\r\n\r\n".data(using: String.Encoding.utf8)!)
//        newSocket.readData(to: "\r\n\r\n".data(using: String.Encoding.utf8)!, withTimeout: -1, tag: 1)
    }
}
