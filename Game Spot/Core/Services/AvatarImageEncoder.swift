import UIKit

enum AvatarImageEncodingError: LocalizedError {

    case couldNotEncode
    case exceedsUploadLimit

    var errorDescription: String? {
        switch self {
        case .couldNotEncode:
            return "Could not prepare the selected photo."
        case .exceedsUploadLimit:
            return "The selected photo is too large."
        }
    }
}

enum AvatarImageEncoder {

    static let maximumPixelDimension: CGFloat = 1_024
    static let maximumByteCount = 5 * 1_024 * 1_024

    private static let compressionQualities: [CGFloat] = [
        0.8,
        0.65,
        0.5,
        0.35
    ]

    static func jpegData(from image: UIImage) throws -> Data {
        let preparedImage = resizedIfNeeded(image)

        for quality in compressionQualities {
            guard let data = preparedImage.jpegData(
                compressionQuality: quality
            ) else {
                throw AvatarImageEncodingError.couldNotEncode
            }

            if data.count <= maximumByteCount {
                return data
            }
        }

        throw AvatarImageEncodingError.exceedsUploadLimit
    }

    private static func resizedIfNeeded(
        _ image: UIImage
    ) -> UIImage {
        let sourceSize = image.size
        let largestDimension = max(
            sourceSize.width,
            sourceSize.height
        )

        guard largestDimension > maximumPixelDimension else {
            return image
        }

        let scale = maximumPixelDimension / largestDimension
        let targetSize = CGSize(
            width: max(1, round(sourceSize.width * scale)),
            height: max(1, round(sourceSize.height * scale))
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(
            size: targetSize,
            format: format
        ).image { _ in
            image.draw(
                in: CGRect(origin: .zero, size: targetSize)
            )
        }
    }
}
