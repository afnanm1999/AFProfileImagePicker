//
//  AFProfileImagePicker.swift
//  AFProfileImagePicker
//
//  Created by Afnan Mirza on 10/6/20.
//  Copyright © 2020 Afnan Mirza. All rights reserved.
//

import AVFoundation
import UIKit
import ImageIO

public protocol AFProfileImagePickerDelegate: AnyObject {
    /// The user canceled out of the image selection operation.
    ///
    /// - Parameter picker: Reference to the Profile Picker.
    ///
    func afImagePickerControllerDidCancel(_ picker: AFProfileImagePicker)

    /// The user completed the operation of either editing, selecting from photo library, or capturing from the camera.  The dictionary uses the editing information keys used in UIImagePickerController.
    ///
    /// - Parameters:
    ///     - picker: Reference to profile picker that completed selection.
    ///     - info: A dictionary containing the original image and the edited image, if an image was picked; The dictionary also contains any relevant editing information. .
    ///
    func afImagePickerController(_ picker: AFProfileImagePicker, didFinishPickingMediaWithInfo info: [String: Any])
}

public class AFProfileImagePicker: UIViewController {

    // MARK: - Properties

    /// Determines how small the image can be scaled.  The default is 1 i.e. it can be made smaller than original.
    public var minimumZoomScale: CGFloat = 1
    /// Determines how large the image can be scaled.  The default is 10.
    public var maximumZoomScale: CGFloat = 10
    /// A value from 0 to 1 to control how brilliant the image shows through the area outside of the crop circle.
    /// 1 is completely opaque and 0 is completely transparent.  The default is .6.
    public var overlayOpacity: CGFloat = 0.6
    /// The background color of the edit screen.  The default is black.
    public var backgroundColor: UIColor = .black
    /// The foreground color of the text on the edit screen. The default is white.
    public var foregroundColor: UIColor = .white
    /// The delegate receives notifications when the user has selected an image or exits image selection.
    weak public var delegate: AFProfileImagePickerDelegate?

    /// Is displaying the photo picker.
    private var isDisplayFromPicker = false
    /// To determine if the crop screen is displayed from the camera path.
    private var isPresentingCamera = false
    /// To determine if the crop screen is displayed from the camera path.
    private var didChooseImage = false
    /// `true` when the snap photo target has been replaced in the `UIImagePickerController`.
    private var isSnapPhotoTargetAdded = false
    /// Set to `true` when camera has been initialized, so it only happens once.
    private var isPreparingStill = false

    /// Session for captureing a still image.
    private var session: AVCaptureSession?
    /// Holds the still image from the camera
    private var stillImageOutput: AVCaptureStillImageOutput?
    /// This class proxy's for the UIImagePickerController.
    private var imagePicker = UIImagePickerController()


    //    /**
    //     *  displays the circle mask
    //     */
    //    UIView* overlayView;
    //    /**
    //     *  holds the image to be moved and cropped
    //     */
    //    UIImageView* imageView;
    //    /**
    //     *  Holds the image for positioning and reasizing
    //     */
    //    UIScrollView* scrollView;
    //    /**
    //     *  Image passed to the edit screen.
    //     */
    //    UIImage*  imageToEdit;
    //    /**
    //     *  @"Move and Scale";
    //     */
    //    UILabel*  titleLabel;
    //    /**
    //     *  selects the image
    //     */
    //    UIButton* chooseButton;
    //    /**
    //     *  cancels cropping
    //     */
    //    UIButton* cancelButton;
    //    /**
    //     *  Rectangular area identifying the crop region
    //     */
    //    CGRect cropRect;
    //
    //    MMSCameraViewController* camera;



    // MARK: - Initalization

    init() {
        super.init()

    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// Edits an Image
    ///
    /// Presents a screen to resize and position the passed image within a circular crop region.
    /// - Parameters:
    ///     - vc: The view controller to present the edit screen from.
    ///     - image: The image to edit.
    public func presentEditScreen(_ vc: UIViewController, with image: UIImage) {

    }

    /** Select image from photo library
     *
     *  Presents the sequnence of screens to select an image from the device's photo library.
     *
     *  @param vc The view controller to present the library selection screen from.
     */
    public func select(fromPhotoLibrary vc: UIViewController) {

    }

    /** Select image from the camera
     *
     *  Presents the camera for positioning a scene and acquiring the image.
     *
     *  @param vc The view controller to present the camera from.
     */
    public func select(fromCamera vc: UIViewController) {

    }
}

// MARK: - UIScrollViewDelegate
//extension AFProfileImagePicker: UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//
//}
