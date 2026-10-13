import Testing
@testable import LuxCore

@Suite struct SHA256Tests {
    @Test(arguments: [
        ("", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"),
        ("abc", "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"),
        ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
         "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"),
    ])
    func standardVectors(input: String, expected: String) {
        #expect(SHA256Digest.hexHash(Array(input.utf8)) == expected)
    }

    @Test func millionAs() {
        #expect(SHA256Digest.hexHash([UInt8](repeating: 0x61, count: 1_000_000))
            == "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0")
    }
}
