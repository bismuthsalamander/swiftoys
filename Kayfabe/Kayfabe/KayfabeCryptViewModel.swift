//
//  KayfabeCryptViewModel.swift
//  Kayfabe
//
//  Created by Cliff Smith on 8/7/24.
//

import Foundation
class KayfabeCryptViewModel {
    let secret: String = "Lorem ipsum dolor sit amet"
    var plaintextVal: String = ""
    var plaintextString: String {
        set {
            plaintextVal = newValue
            print("Set value to \(plaintextVal)")
            ciphertextString = "ENCRYPTED " + plaintextVal
            print("Set ciphertext string to \(ciphertextString)")
        }
        get {
            plaintextVal
        }
    }
    var ciphertextString = "firstCiphertextString"
}
