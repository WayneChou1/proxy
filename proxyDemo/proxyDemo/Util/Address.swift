//
//  Adress.swift
//  proxyDemo
//
//  Created by 方冬冬 on 2021/1/18.
//

import Foundation

struct Address: CustomStringConvertible, Comparable {

    // Comparing IP addresses of different families are undefined.
    // But currently, IPv4 is considered smaller than IPv6 address. Do NOT depend on this behavior.
    static public func < (lhs: Address, rhs: Address) -> Bool {
        switch (lhs.address, rhs.address) {
        case (.IPv4(let addrl), .IPv4(let addrr)):
            return addrl.s_addr.byteSwapped < addrr.s_addr.byteSwapped
        case (.IPv6(var addrl), .IPv6(var addrr)):
            let ms = MemoryLayout.size(ofValue: addrl)
            return (withUnsafeBytes(of: &addrl) { ptrl in
                withUnsafeBytes(of: &addrr) { ptrr in
                    return memcmp(ptrl.baseAddress!, ptrr.baseAddress!, ms)
                }
            }) < 0
        case (.IPv4, .IPv6):
            return true
        case (.IPv6, .IPv4):
            return false
        }
    }

//    static public func == (lhs: Address.ip, rhs: Address.ip) -> Bool {
//        switch (lhs, rhs) {
//        case (.IPv4(let addrl), .IPv4(let addrr)):
//            return addrl.s_addr == addrr.s_addr
//        case (.IPv6(let addrl), .IPv6(let addrr)):
//            return addrl.__u6_addr.__u6_addr32 == addrr.__u6_addr.__u6_addr32
//        default:
//            return false
//        }
//    }


    var description: String

    public enum Family {
        case IPv4, IPv6
    }

    public enum ip: Equatable {
        public static func == (lhs: Address.ip, rhs: Address.ip) -> Bool {
            return lhs.asUInt128 == rhs.asUInt128
        }


        case IPv4(in_addr), IPv6(in6_addr)

        public var asUInt128: UInt128 {
            switch self {
            case .IPv4(let addr):
                return UInt128(addr.s_addr.byteSwapped)
            case .IPv6(var addr):
                var upperBits: UInt64 = 0, lowerBits: UInt64 = 0
                withUnsafeBytes(of: &addr) {
                    upperBits = $0.load(as: UInt64.self).byteSwapped
                    lowerBits = $0.load(fromByteOffset: MemoryLayout<UInt64>.size, as: UInt64.self).byteSwapped
                }
                return UInt128(upperBits: upperBits, lowerBits: lowerBits)
            }
        }
    }

    public let family: Family
    public let address: ip

    public init(fromInAddr addr: in_addr) {
        family = .IPv4
        address = .IPv4(addr)
        description = ""
    }

    public init(fromIn6Addr addr6: in6_addr) {
        family = .IPv6
        address = .IPv6(addr6)
        description = ""
    }

    public init?(fromString string: String) {
        var addr = in_addr()

        if (string.withCString {
            return inet_pton(AF_INET, $0, &addr)
        }) == 1 {
            self.init(fromInAddr: addr)
            presentation = string
        } else {
            var addr6 = in6_addr()
            if (string.withCString {
                return inet_pton(AF_INET6, $0, &addr6)
            }) == 1 {
                self.init(fromIn6Addr: addr6)
                presentation = string
            } else {
                return nil
            }
        }
    }

    public lazy var presentation: String = {
        switch self.address {
        case .IPv4(var addr):
            var buffer = [Int8](repeating: 0, count: Int(INET_ADDRSTRLEN))
            var p: UnsafePointer<Int8>! = nil
            withUnsafePointer(to: &addr) {
                p = inet_ntop(AF_INET, $0, &buffer, UInt32(INET_ADDRSTRLEN))
            }
            return String(cString: p)
        case .IPv6(var addr):
            var buffer = [Int8](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            var p: UnsafePointer<Int8>! = nil
            withUnsafePointer(to: &addr) {
                p = inet_ntop(AF_INET6, $0, &buffer, UInt32(INET6_ADDRSTRLEN))
            }
            return String(cString: p)
        }
    }()
}
