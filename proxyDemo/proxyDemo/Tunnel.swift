//
//  Tunnel.swift
//  proxyDemo
//
//  Created by 方冬冬 on 2021/1/20.
//

import Foundation

protocol TunnelDelegate : class {
    func tunnelDidClose(_ tunnel: Tunnel)
}

class Tunnel {

    /// The proxy socket.
    var proxySocket: HTTPProxyGCDAsyncSocket

    /// The adapter socket connecting to remote.
    var adapterSocket: HTTPAdapter?

    /// The delegate instance.
    weak var delegate: TunnelDelegate?

    init(proxySocket: HTTPProxyGCDAsyncSocket) {
        self.proxySocket = proxySocket
//        self.proxySocket.delegate = self
    }
}
