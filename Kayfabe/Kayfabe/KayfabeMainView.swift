//
//  ContentView.swift
//  Kayfabe
//
//  Created by Cliff Smith on 8/7/24.
//

import SwiftUI
import CryptoKit

struct KayfabeMainView: View {
    @State var lastDecryptedCiphertext = "(none)"
    @State var b64Plaintext = ""
    @State var crypt = KayfabeCryptViewModel()
    @State var plaintext = "" {
        didSet {
            print("Changed plaintext")
            changed += 1
        }
    }
    @State var nonce: ChaChaPoly.Nonce = ChaChaPoly.Nonce()
    @State var nonceStr = "(none)"
    @State var tag = ""
    @State var ciphertext = ""
    @State var changed = 0
    let key = SymmetricKey(size: .bits256)
    
    func generateCiphertext() -> ChaChaPoly.SealedBox {
        ciphertext = "Encrypted " + plaintext
        var pt = generatePlaintext()
        let box = try! ChaChaPoly.seal(pt, using: key, nonce: nil)
        return box
//        let tag = box.tag
//        let nonce = box.nonce
//        let out = box.ciphertext
//        let tag64 = out.base64EncodedString()
    }
    
    func generatePlaintext() -> Data {
        var str = plaintext
        if (str.count > 4) {
            str = String(str[...str.index(str.startIndex, offsetBy: 3)])
        }
        return str.data(using: .ascii)!
    }
    
    func updateCiphertext() {
        let s = String(plaintext).data(using:.ascii)
        b64Plaintext = s!.base64EncodedString()
        let box = generateCiphertext()
        tag = box.tag.base64EncodedString()
        nonce = box.nonce
        nonceStr = "(automatically generated)"
        ciphertext = box.ciphertext.base64EncodedString()
        let outbox = try! ChaChaPoly.open(box, using: key)
        print(outbox)
        print(outbox.base64EncodedString())
    }
    
    func attemptDecryption() {
        let ct = Data(base64Encoded: ciphertext)
        let tag = Data(base64Encoded: tag)
        let nonce = nonce
        guard let ct = ct else {
            lastDecryptedCiphertext = "Error b64 decoding ciphertext"
            return
        }
        guard let tag = tag else {
            lastDecryptedCiphertext = "Error b64 decoding tag"
            return
        }
        let box = try? ChaChaPoly.SealedBox(nonce: nonce, ciphertext: ct, tag: tag)
        guard let box = box else {
            lastDecryptedCiphertext = "Error constructing SealedBox"
            return
        }
        let out = try? ChaChaPoly.open(box, using: key)
        guard let out = out else {
            lastDecryptedCiphertext = "Error decrypting"
            return
        }
        lastDecryptedCiphertext = String(data: out, encoding: .ascii) ?? "(error base64 decoding)"
    }
    var body: some View {
        VStack {
            HStack {
                Text("Input:")
                TextField("Input string", text: $plaintext)
                    .onChange(of: plaintext) {
                        changed += 1
                        updateCiphertext()
                    }
            }
            HStack {
                Text("B64 input:")
                TextField("B64", text: $b64Plaintext)
            }
            HStack {
                Text("Ciphertext:")
                TextField("Input string", text: $ciphertext)
            }
            HStack {
                Text("Nonce:")
                TextField("Input string", text: $nonceStr)
            }
            HStack {
                Text("Tag:")
                TextField("Input string", text: $tag)
            }
            HStack {
                Text("N changes:")
                Text("\(changed)")
            }
            Button {
                print("Text 1 is \(plaintext) and text 2 is \(ciphertext)")
                attemptDecryption()
            } label: {
                Text("Decrypt")
            }
            HStack {
                Text("Decrypted plaintext: ")
                Text("\(lastDecryptedCiphertext)")
            }
        }
        .padding()
    }
}

#Preview {
    KayfabeMainView()
}
