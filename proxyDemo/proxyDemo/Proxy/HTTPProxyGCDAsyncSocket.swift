//
//  HTTPProxyGCDAsyncSocket.swift
//  proxyDemo
//
//  Created by 方冬冬 on 2021/1/18.
//

import Foundation

class HTTPProxyGCDAsyncSocket: NSObject,GCDAsyncSocketDelegate {

    /// The remote host to connect to.
    public var destinationHost: String!

    /// The remote port to connect to.
    public var destinationPort: Int!

    public var socket: GCDAsyncSocket!

    init(socket:GCDAsyncSocket) {
        self.socket = socket
    }

    func openSocket() {
        self.socket.delegate = self
        socket.readData(to: Utils.HTTPData.DoubleCRLF, withTimeout: -1, tag: 1)
    }

    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("error descrtion:\(String(describing: err?.localizedDescription))")
    }

    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {

    }

    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {

    }

    func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {

    }

}
