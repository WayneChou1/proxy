//
//  Proxy.swift
//  proxyDemo
//
//  Created by 方冬冬 on 2021/1/18.
//

import Foundation

open class Proxy {

    var port:Port
    var address:Address?

    init(address: Address?, port: Port) {
        self.address = address
        self.port = port
    }

}
