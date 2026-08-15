import XCTest
import UIKit
@testable import Game_Spot

final class AvatarImageEncoderTests: XCTestCase {

    func testLargeImageIsResizedWithinStorageLimits() throws {
        let sourceSize = CGSize(width: 4_000, height: 3_000)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        let image = UIGraphicsImageRenderer(
            size: sourceSize,
            format: format
        ).image { context in
            UIColor.systemBlue.setFill()
            context.fill(
                CGRect(origin: .zero, size: sourceSize)
            )
        }

        let data = try AvatarImageEncoder.jpegData(from: image)
        let encodedImage = try XCTUnwrap(UIImage(data: data))

        XCTAssertLessThanOrEqual(
            data.count,
            AvatarImageEncoder.maximumByteCount
        )
        XCTAssertLessThanOrEqual(
            max(encodedImage.size.width, encodedImage.size.height),
            AvatarImageEncoder.maximumPixelDimension
        )
    }
}
