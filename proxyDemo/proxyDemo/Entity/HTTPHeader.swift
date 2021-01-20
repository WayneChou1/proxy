//
//  HTTPHeader.swift
//  proxyDemo
//
//  Created by 方冬冬 on 2021/1/20.
//

import Foundation

class HTTPHeader {

    public enum HTTPHeaderError: Error {
        case malformedHeader, invalidRequestLine, invalidHeaderField, invalidConnectURL, invalidConnectPort, invalidURL, missingHostField, invalidHostField, invalidHostPort, invalidContentLength, illegalEncoding
    }

    var HTTPVersion: String
    var HTTPMethod: String
    var isConnect: Bool = false
    var path: String
    var foundationURL: Foundation.URL?
    var homemadeURL: HTTPURL?
    var host: String
    var port: Int
    // just assume that `Content-Length` is given as of now.
    // Chunk is not supported yet.
    open var contentLength: Int = 0
    open var headers: [(String, String)] = []
    open var rawHeader: Data?

    init(headerData:Data) throws {

        let headerString = String.init(data: headerData, encoding: String.Encoding.utf8)
        let lines = headerString!.components(separatedBy: "\r\n")
        print("lines:\(lines)")

        let request = lines[0].components(separatedBy: " ")
        print("request:\(request)")

        HTTPMethod = request[0]
        path = request[1]
        HTTPVersion = request[2]

        for line in lines[1..<lines.count-2] {
            let header = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard header.count == 2 else {
                throw HTTPHeaderError.invalidHeaderField
            }
            headers.append((String(header[0]).trimmingCharacters(in: CharacterSet.whitespaces), String(header[1]).trimmingCharacters(in: CharacterSet.whitespaces)))
        }

        if HTTPMethod.uppercased() == "CONNECT" {
            isConnect = true

            let urlInfo = path.components(separatedBy: ":")
            guard urlInfo.count == 2 else {
                throw HTTPHeaderError.invalidConnectURL
            }
            host = urlInfo[0]
            guard let port = Int(urlInfo[1]) else {
                throw HTTPHeaderError.invalidConnectPort
            }
            self.port = port

            self.contentLength = 0
        } else {
            var resolved = false

            host = ""
            port = 80

            if let _url = Foundation.URL(string: path) {
                foundationURL = _url
                if foundationURL!.host != nil {
                    host = foundationURL!.host!
                    port = foundationURL!.port ?? 80
                    resolved = true
                }
            } else {
                guard let _url = HTTPURL(string: path) else {
                    throw HTTPHeaderError.invalidURL
                }
                homemadeURL = _url
                if homemadeURL!.host != nil {
                    host = homemadeURL!.host!
                    port = homemadeURL!.port ?? 80
                    resolved = true
                }
            }

            if !resolved {
                var url: String = ""
                for (key, value) in headers {
                    if "Host".caseInsensitiveCompare(key) == .orderedSame {
                        url = value
                        break
                    }
                }
                guard url != "" else {
                    throw HTTPHeaderError.missingHostField
                }

                let urlInfo = url.components(separatedBy: ":")
                guard urlInfo.count <= 2 else {
                    throw HTTPHeaderError.invalidHostField
                }
                if urlInfo.count == 2 {
                    host = urlInfo[0]
                    guard let port = Int(urlInfo[1]) else {
                        throw HTTPHeaderError.invalidHostPort
                    }
                    self.port = port
                } else {
                    host = urlInfo[0]
                    port = 80
                }
            }

            for (key, value) in headers {
                if "Content-Length".caseInsensitiveCompare(key) == .orderedSame {
                    guard let contentLength = Int(value) else {
                        throw HTTPHeaderError.invalidContentLength
                    }
                    self.contentLength = contentLength
                    break
                }
            }
        }
    }

    open func removeHeader(_ key: String) -> String? {
        for i in 0..<headers.count {
            if headers[i].0.caseInsensitiveCompare(key) == .orderedSame {
                let (_, value) = headers.remove(at: i)
                return value
            }
        }
        return nil
    }

    open func removeProxyHeader() {
        let ProxyHeader = ["Proxy-Authenticate", "Proxy-Authorization", "Proxy-Connection"]
        for header in ProxyHeader {
            _ = removeHeader(header)
        }
    }
}
