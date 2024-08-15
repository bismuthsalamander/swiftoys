//
//  ContentView.swift
//  Kayfabe
//

import SwiftUI
import CryptoKit
import CoreFoundation

struct KayfabeMainView: View {
    @State var lastDecryptedCiphertext = "(none)"
    @State var crypt = KayfabeCryptViewModel()
    @State var plaintext = ""
    @State var nonce: ChaChaPoly.Nonce = ChaChaPoly.Nonce()
    @State var nonceStr = "(none)"
    @State var tag = ""
    @State var ciphertext = ""
    let key = SymmetricKey(size: .bits256)
    var maxLen = 4;
    
    func generateCiphertext() -> ChaChaPoly.SealedBox {
        let pt = generatePlaintext()
        return try! ChaChaPoly.seal(pt, using: key, nonce: nil)    }
    
    func generatePlaintext() -> Data {
        var str = plaintext
        if (str.count > crypt.maxLen) {
            str = String(str[...str.index(str.startIndex, offsetBy: crypt.maxLen - 1)])
        }
        return str.data(using: .ascii)!
    }
    
    func updateCiphertext() {
        let s = String(plaintext).data(using:.ascii)
        let box = generateCiphertext()
        tag = box.tag.base64EncodedString()
        nonce = box.nonce
        nonceStr = "(automatically generated)"
        ciphertext = box.ciphertext.base64EncodedString()
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
                Text("As you type in the input field below, the app will automatically encrypt the plaintext using a key stored locally. Touch the Decrypt button to decrypt it. Can you successfully instrument the app to decrypt the entire input string?")
            }
            HStack {
                Text("Input:")
                if #available(iOS 17.0, *) {
                    TextField("Input string", text: $plaintext)
                        .onChange(of: plaintext) {
                            updateCiphertext()
                        }
                } else {
                    TextField("Input string", text: $plaintext)
                        .onChange(of: plaintext) { thing in
                            updateCiphertext()
                        }
                }
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
            Button {
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
