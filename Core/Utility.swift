//
//  Utils.swift
//  Spider
//
//  Created by jifu on 2018/10/25.
//  Copyright © 2018 Spider. All rights reserved.
//

import Foundation

enum RequestContentError: Error {
    case invalidURL
    case serverInternalError
    case noData
}

// MARK: -
class Utility {
    
    static func fetchWebCotent(with address: String, handler: @escaping (_ err: RequestContentError?, _ content: String?) -> Void) {
        
        guard let url = URL(string: address) else {
            return handler(.invalidURL, nil)
        }
        URLCache.shared.removeAllCachedResponses()
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        request.addValue("keep-alive", forHTTPHeaderField: "Connection")
        request.addValue("no-cache", forHTTPHeaderField: "Pragma")
        request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.87 Safari/537.36", forHTTPHeaderField: "User-Agent")

        request.cachePolicy = .reloadIgnoringLocalCacheData
        URLSession.shared.dataTask(with: request) { (data, response, error) in

            guard error == nil else { return handler(.serverInternalError, nil) }
            guard let data = data  else { return  handler(.noData, nil) }
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return handler(.serverInternalError, nil) }
            handler(nil, String(data: data
                , encoding: String.Encoding.utf8))
           
        }.resume()
    }
    
    static func decodeThunder(string encodedStr: String) -> String? {
        let rawStr = encodedStr[encodedStr.index(encodedStr.startIndex, offsetBy: 10)..<encodedStr.endIndex]
        guard let rawData = Data(base64Encoded: String(rawStr),  options: [.ignoreUnknownCharacters]) else {return nil}
        let encodings: [String.Encoding] = [ .utf8,.ascii, .gb_18030_2000]
        var str: String? = String(data: rawData, encoding: encodings.last!)
        while str == nil, let encodeing = encodings.last {
            str = String(data: rawData, encoding: encodeing)
        }
        
        if let str = str?.removingPercentEncoding, str.hasPrefix("AA"), str.hasSuffix("ZZ") {
            let startIndex = str.index(str.startIndex, offsetBy: 2)
            let endIndex = str.index(str.endIndex, offsetBy: -2)
            
            return String(str[startIndex..<endIndex])
        }
        
        return nil
    }
    
    static func encodeThunder(string rawStr: String) -> String? {
        guard let wrappedStr = "AA\(rawStr)ZZ".data(using: .utf8)?.base64EncodedString() else {return nil}
        
        return "thunder://\(wrappedStr)"
    }
    
    static func urlScheme(for link:String) -> ResourceScheme? {
        let schemes = link.split(separator: ":")
        guard schemes.count > 1  else {return nil}
        let scheme = ResourceScheme(rawValue: String(schemes[0]))
        return scheme
    }
    
    static func retrieveNameAndSize(from url: String) -> (name: String, size: String?)? {
        
        var decodedURL = url.removingPercentEncoding
        //MARK: decode url string will be failure when string encoding is gb2312
        if decodedURL == nil {
            decodedURL = url.removingPercentEncoding(using: String.Encoding.gb_18030_2000)
        }
        
        guard let url = decodedURL else {return nil}
        guard let scheme = urlScheme(for: url) else {return nil}
        switch scheme {
        case .http, .https, .ftp, .ftps:
            let name = (url as NSString).lastPathComponent
            return (name, nil)
        case .thunder:
            if let link = decodeThunder(string: url) {
                return retrieveNameAndSize(from: link)
            }
            return  ("迅雷专用链接", nil)
        case .ed2k:
            let components = url.split(separator: "|")
            guard components.count >= 5 else {return nil}
            let name = String(components[2])
            let size = (String(components[3]) as NSString).longLongValue.humanReadableSize
            return  (name, size)
        case .magnet:
            return  ("种子文件-\(url)", nil)
            
        }
    }
    
}

// MARK: -
extension String.Encoding {
    static let gb_18030_2000 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
}

// MARK: -
extension String {
    func bytesByRemovingPercentEncoding(using encoding: String.Encoding) -> Data {
        struct My {
            static let regex = try! NSRegularExpression(pattern: "(%[0-9A-F]{2})|(.)", options: .caseInsensitive)
        }
        var bytes = Data()
        let nsSelf = self as NSString
        for match in My.regex.matches(in: self, range: NSRange(0..<self.utf16.count)) {
            if match.range(at: 1).location != NSNotFound {
                let hexString = nsSelf.substring(with: NSMakeRange(match.range(at: 1).location+1, 2))
                bytes.append(UInt8(hexString, radix: 16)!)
            } else {
                let singleChar = nsSelf.substring(with: match.range(at: 2))
                bytes.append(singleChar.data(using: encoding) ?? "?".data(using: .ascii)!)
            }
        }
        return bytes
    }
    
    func removingPercentEncoding(using encoding: String.Encoding) -> String? {
        return String(data: bytesByRemovingPercentEncoding(using: encoding), encoding: encoding)
    }
}

// MARK: -
extension Int64 {
    var humanReadableSize: String {
        let formatter = ByteCountFormatter()
        return formatter.string(fromByteCount: self)
    }
}

//

func DebugLog<T>(_ message:T, file:String = #file, function:String = #function,
                     line:Int = #line) {
    #if DEBUG
    //获取文件名
    let fileName = (file as NSString).lastPathComponent
    //打印日志内容
    let text =  "\(fileName):\(line) \(function) | \(message)"
    print(text)
    #endif
}

