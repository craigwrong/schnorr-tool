import ArgumentParser
import ECHelper
import Base16
import Bech32
import Crypto
import Foundation

struct SchnorrTool: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A utility for Schnorr signature and Bitcoin's Elliptic Curve operations.",
        
        version: "1.0.0",
        
        subcommands: [Hash.self, Tweak.self, InternalKey.self, Tweak.self, OutputKey.self, OutputScript.self, Address.self])
    
}

struct HashOptions: ParsableArguments {
    @Argument(
        help: "The value to apply SHA-256.")
    var value: String
}

struct Options: ParsableArguments {
    @Flag(name: [.customLong("hex-output"), .customShort("x")],
          help: "Use hexadecimal notation for the result.")
    var hexadecimalOutput = false
    
    @Argument(
        help: "A group of integers to operate on.")
    var values: [Int] = []
}

extension SchnorrTool {
    struct Hash: ParsableCommand {
        static var configuration =
        CommandConfiguration(abstract: "Hashes a value with SHA-256.")
        
        // The `@OptionGroup` attribute includes the flags, options, and
        // arguments defined by another `ParsableArguments` type.
        @OptionGroup var options: HashOptions
        
        mutating func run() {
            let input = options.value
            var hasher = Crypto.SHA256()
            hasher.update(data: try! Data(base16Encoded: input))
            let digest = hasher.finalize()
            let prefixedHash = digest.description
            let hash = prefixedHash.dropFirst("SHA256 digest: ".count)
            print(hash)
        }
    }
    
    struct InternalKey: ParsableCommand {
        static var configuration =
        CommandConfiguration(abstract: "Computes an internal key.")
        
        // The `@OptionGroup` attribute includes the flags, options, and
        // arguments defined by another `ParsableArguments` type.
        @OptionGroup var options: HashOptions
        
        mutating func run() {
            guard let data = try? Data(base16Encoded: options.value) else {
                return
            }
            var secretKey: UnsafePointer<UInt8>?
            data.withUnsafeBytes { (unsafeBytes) in
                secretKey = unsafeBytes.bindMemory(to: UInt8.self).baseAddress!
            }
            print(String(cString: computeInternalKey(secretKey)))
        }
    }
    
    struct Tweak: ParsableCommand {
        static var configuration =
        CommandConfiguration(abstract: "Hashes a value with SHA-256.")
        
        // The `@OptionGroup` attribute includes the flags, options, and
        // arguments defined by another `ParsableArguments` type.
        @OptionGroup var options: HashOptions
        
        mutating func run() {
            guard let _ = try? Data(base16Encoded: options.value) else {
                fatalError("Wrong input.")
            }
            var hasher1 = Crypto.SHA256()
            hasher1.update(data: "TapTweak".data(using: .utf8)!)
            let prefixedTagHash = hasher1.finalize().description
            let tagHash = prefixedTagHash.dropFirst("SHA256 digest: ".count)
            var hasher = Crypto.SHA256()
            //print("tagHash: \(tagHash)")
            hasher.update(data: try! Data(base16Encoded: tagHash + tagHash + options.value))
            let digest = hasher.finalize()
            let hash = digest.description.dropFirst("SHA256 digest: ".count)
            print(hash)
        }
    }
    
    struct OutputKey: ParsableCommand {
        struct Options: ParsableArguments {
            @Argument(
                help: "The output public key in base 16.")
            var values: [String]
        }
        
        static var configuration =
        CommandConfiguration(abstract: "Computes an output key.")
        
        // The `@OptionGroup` attribute includes the flags, options, and
        // arguments defined by another `ParsableArguments` type.
        @OptionGroup var options: Options
        
        mutating func run() {
            guard let internalKeyData = try? Data(base16Encoded: options.values[0]),
                  var tweakData = try? Data(base16Encoded: options.values[1]) else {
                      return
                  }
            var internalKey: UnsafePointer<UInt8>?
            internalKeyData.withUnsafeBytes { (unsafeBytes) in
                internalKey = unsafeBytes.bindMemory(to: UInt8.self).baseAddress!
            }
            var tweak: UnsafeMutablePointer<UInt8>?
            tweakData.withUnsafeMutableBytes { (unsafeBytes) in
                tweak = unsafeBytes.bindMemory(to: UInt8.self).baseAddress!
            }
            print(String(cString: computeOutputKey(internalKey, tweak)))
        }
    }
    
    struct OutputScript: ParsableCommand {
        struct Options: ParsableArguments {
            @Argument(
                help: "The output key in hex format.")
            var values: [String]
        }
        
        static var configuration =
        CommandConfiguration(abstract: "Computes an output script.")
        
        // The `@OptionGroup` attribute includes the flags, options, and
        // arguments defined by another `ParsableArguments` type.
        @OptionGroup var options: Options
        
        mutating func run() {
            guard let outputKeyData = try? Data(base16Encoded: options.values[0]) else {
                      return
                  }
            var prefix = UInt16(0x5120).bigEndian
            let prefixData = Data(bytes: &prefix, count: MemoryLayout<UInt16>.size)
            let scriptData = prefixData + outputKeyData
            print(scriptData.base16EncodedString())
        }
    }

    
    struct Address: ParsableCommand {
        struct Options: ParsableArguments {
            @Argument(
                help: "The output key in hex format.")
            var values: [String]
        }
        
        static var configuration =
        CommandConfiguration(abstract: "Computes a Bech32m address.")
        
        // The `@OptionGroup` attribute includes the flags, options, and
        // arguments defined by another `ParsableArguments` type.
        @OptionGroup var options: Options
        
        mutating func run() {
            guard let programData = try? Data(base16Encoded: options.values[0]) else {
                return
            }
            guard let encoded = try? SegwitAddrCoder(bech32m: true).encode(hrp: "bc", version: 1, program: programData) else {
                return
            }
            print(encoded)
        }
    }
}

//func customCompletion(_ s: [String]) -> [String] {
//    return (s.last ?? "").starts(with: "a")
//    ? ["aardvark", "aaaaalbert"]
//    : ["hello", "helicopter", "heliotrope"]
//}

SchnorrTool.main()
