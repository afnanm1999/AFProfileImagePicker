//
//  UIImage+Cropping.swift
//  AFProfileImagePicker
//
//  Created by Afnan Mirza on 10/6/20.
//  Copyright © 2020 Afnan Mirza. All rights reserved.
//

import CoreFoundation
import UIKit

extension UIImage {
    /// Calculates a return size by aspect scaling the` fromSize` to fit within the destination size while giving priority to the width or height depending on which preference will maintain both the return width and height within the destination ie the return size will return a new size where both width and height are less than or equal to the destinations.
    ///
    /// - Parameters:
    ///   - fromSize: Size to be transformed.
    ///   - toSize: Destination size.
    ///
    /// - Returns: Aspect scaled size
    public class func scale(_ fromSize: CGSize, to toSize: CGSize) -> CGSize {
        var scaleSize: CGSize = .zero

        // if the wideth is the shorter dimension
        if toSize.width < toSize.height {
            if fromSize.width >= toSize.width {  // give priority to width if it is larger than the destination width
                scaleSize.width = round(toSize.width)
                scaleSize.height = round(scaleSize.width * fromSize.height / fromSize.width)
            } else if fromSize.height >= toSize.height {  // then give priority to height if it is larger than destination height
                scaleSize.height = round(toSize.height)
                scaleSize.width = round(scaleSize.height * fromSize.width / fromSize.height)
            } else {  // otherwise the source size is smaller in all directions.  Scale on width
                scaleSize.width = round(toSize.width)
                scaleSize.height = round(scaleSize.width * fromSize.height / fromSize.width)

                if scaleSize.height > toSize.height { // but if the new height is larger than the destination then scale height
                    scaleSize.height = round(toSize.height)
                    scaleSize.width = round(scaleSize.height * fromSize.width / fromSize.height)
                }
            }
        } else {  // else height is the shorter dimension
            if fromSize.height >= toSize.height {  // then give priority to height if it is larger than destination height
                scaleSize.height = round(toSize.height)
                scaleSize.width = round(scaleSize.height * fromSize.width / fromSize.height)
            } else if fromSize.width >= toSize.width {  // give priority to width if it is larger than the destination width
                scaleSize.width = round(toSize.width)
                scaleSize.height = round(scaleSize.width * fromSize.height / fromSize.width)
            } else {  // otherwise the source size is smaller in all directions.  Scale on width
                scaleSize.width = round(toSize.width)
                scaleSize.height = round(scaleSize.width * fromSize.height / fromSize.width)

                if scaleSize.height > toSize.height { // but if the new height is larger than the destination then scale height
                    scaleSize.height = round(toSize.height)
                    scaleSize.width = round(scaleSize.height * fromSize.width / fromSize.height)
                }
            }
        }

        return scaleSize
    }

    /// Returns a new `UIImage` cut from the `cropArea` of the underlying image. It first scales the underlying image to the scale size before cutting the crop area from it. The returned `CGImage` is in the dimensions of the `cropArea` and it is oriented the same as the underlying `CGImage` as is the `imageOrientation`.
    ///
    /// - Parameters:
    ///   - cropArea: The rectangle with in the frame size to crop.
    ///   - frameSize: The size of the frame that is currently showing the image.
    ///
    /// - Returns: A `UIImage` cropped to the input dimensions and oriented like the `UIImage`.
    public func cropRectangle(cropArea cropRect: CGRect, inFrame frameSize: CGSize) -> UIImage? {
        var frameSizeLocal = frameSize
        frameSizeLocal = CGSize(width: round(frameSize.width), height: round(frameSize.height))

        // Resize the image to match the zoomed content size
        let img = scaleBitmap(toSize: frameSizeLocal)

        // Crop the resized image to the crop rectangel.
        if let cropRef = img?.cgImage?.cropping(to: transposeCropRect(cropRect, inDimension: cropRect, forOrientation: imageOrientation)) {
            return UIImage(cgImage: cropRef, scale: 1.0, orientation: imageOrientation)
        }

        return nil
    }

    /// Transposes the origin of the crop rectangle to match the orientation of the underlying `CGImage`. For some orientations, the height and width are swaped.
    ///
    /// - Parameters:
    ///     - cropRect: The crop rectangle as layed out on the screen.
    ///     - fromRect: The rectangle the crop rect sits inside.
    ///     - toRect: The rectangle the crop rect will be removed from
    ///
    /// - Returns: The crop rectangle scaled to the rectangle.
    public func transposeCropRect(_ cropRect: CGRect, fromBound fromRect: CGRect, toBound toRect: CGRect) -> CGRect {
        let scale = toRect.size.width / fromRect.size.width
        return CGRect(x: round(cropRect.origin.x * scale),
                      y: round(cropRect.origin.y * scale),
                      width: round(cropRect.size.width * scale),
                      height: round(cropRect.size.height * scale))
    }

    // MARK: - Private Methods
    private func transposeCropRect(_ cropRect: CGRect, inDimension boundSize: CGRect, forOrientation orientation: UIImage.Orientation) -> CGRect {
        var transposedRect = cropRect

        switch orientation {
        case .left:
            transposedRect.origin.x = boundSize.height - (cropRect.size.height + cropRect.origin.y)
            transposedRect.origin.y = cropRect.origin.x
            transposedRect.size = CGSize(width: cropRect.size.height, height: cropRect.size.width)
        case .right:
            transposedRect.origin.x = cropRect.origin.y
            transposedRect.origin.y = boundSize.width - (cropRect.size.width + cropRect.origin.x)
            transposedRect.size = CGSize(width: cropRect.size.height, height: cropRect.size.width)
        case .down:
            transposedRect.origin.x = boundSize.width - (cropRect.size.width + cropRect.origin.x)
            transposedRect.origin.y = boundSize.height - (cropRect.size.height + cropRect.origin.y)
        case .downMirrored:
            transposedRect.origin.x = cropRect.origin.x
            transposedRect.origin.y = boundSize.height - (cropRect.size.height + cropRect.origin.y)
        case .leftMirrored:
            transposedRect.origin.x = cropRect.origin.y
            transposedRect.origin.y = cropRect.origin.x
            transposedRect.size = CGSize(width: cropRect.size.height, height: cropRect.size.width)
        case .rightMirrored:
            transposedRect.origin.x = boundSize.height - (cropRect.size.height + cropRect.origin.y)
            transposedRect.origin.y = boundSize.width - (cropRect.size.width + cropRect.origin.x)
            transposedRect.size = CGSize(width: cropRect.size.height, height: cropRect.size.width)
        case .upMirrored:
            transposedRect.origin.x = boundSize.width - (cropRect.size.width + cropRect.origin.x)
            transposedRect.origin.y = cropRect.origin.y
        default:
            break
        }

        return transposedRect
    }

    /// Returns an `UIImage` scaled to the input dimensions. Often times the underlining `CGImage` does not match the orientation of the `UIImage`. This routing scales the `UIImage` dimensions not the `CGImage`, and so it swaps the height and width of the scale size when it detects the UIImage is oriented differently.
    ///
    /// - Parameter scaleSize: The dimensions to scale the bitmap to.
    ///
    /// - Returns: A reference to a `UIImage` created from the scaled bitmap.
    private func scaleBitmap(toSize scaleSize: CGSize) -> UIImage? {
        var scaleSizeLocal = scaleSize
        // Round the size of the underlying CGImage and the input size.
        scaleSizeLocal = CGSize(width: round(scaleSize.width), height: round(scaleSize.height))

        // if the underlying CGImage is oriented differently than the UIImage then swap the width and height of the scale size. This method assumes the size passed is a request on the UIImage's orientation.
        if imageOrientation == .left || imageOrientation == .right {
            scaleSizeLocal = CGSize(width: round(scaleSize.height), height: round(scaleSize.width))
        }

        var returnImage: UIImage?

        // Create a bitmap context in the dimensions of the scale size and draw the underlying CGImage into the context.
        if let cgImage = cgImage,
           let colorSpace = cgImage.colorSpace {

            if let context = CGContext(data: nil,
                                       width: Int(scaleSizeLocal.width),
                                       height: Int(scaleSizeLocal.height),
                                       bitsPerComponent: cgImage.bitsPerComponent,
                                       bytesPerRow: 0,
                                       space: colorSpace,
                                       bitmapInfo: cgImage.bitmapInfo.rawValue) {

                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: scaleSizeLocal.width, height: scaleSizeLocal.height))

                // Realize the CGImage from the context.
                if let imageRef = context.makeImage() {
                    returnImage = UIImage(cgImage: imageRef)
                }
            } else {
                // Context creation failed, so return a copy of the image, and log the error.
                NSLog("nil Bitmap Context in scaleBitmapToSize")
                returnImage = UIImage(cgImage: cgImage)
            }
        }

        return returnImage
    }
}
