//
//  ViewController.swift
//  proxyDemo
//
//  Created by 方冬冬 on 2021/1/18.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

    var proxyServer: ProxyServer!

    let sessionManager: Session = {

        //2
        let configuration = URLSessionConfiguration.af.default

        configuration.connectionProxyDictionary = ["HTTPEnable":true,
                                                   "HTTPProxy":"127.0.0.1",
                                                   "HTTPPort":8888,
                                                   "HTTPSEnable":true,
                                                   "HTTPSProxy":"127.0.0.1",
                                                   "HTTPSPort":8888
        ]

        //3
        configuration.timeoutIntervalForRequest = 30
        //4
        return Session(configuration: configuration)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let proxy = Proxy.init(address: nil, port: Port.init(port: UInt16(8888)))
        proxyServer = ProxyServer.init(proxy: proxy)

        do {
            try proxyServer.start()
        } catch {
            print(error)
        }

        request()
    }

    func request() {
        sleep(3)
        let request = sessionManager.request("https://www.baidu.com/").response { (response) in
            print("response:\(response)")
        }
    }

}

