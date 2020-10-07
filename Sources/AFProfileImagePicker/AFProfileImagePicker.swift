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
import MobileCoreServices

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
    func afImagePickerController(_ picker: AFProfileImagePicker, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any])
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
    public weak var delegate: AFProfileImagePickerDelegate?

    // MARK: - Private Properties

    private let overlayInset: CGFloat = 10

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
    /// The view controller that presented the AFImagePickerController
    private var presentingVC: UIViewController?

    /// Displays the circle mask.
    private var overlayView = UIView()
    /// Holds the image for positioning and reasizing.
    private var scrollView = UIScrollView()
    /// Holds the image to be moved and cropped.
    private var imageView = UIImageView()
    /// Move and Scale
    private var titleLabel = UILabel()
    /// Cancels cropping.
    private var cancelButton = UIButton()
    /// Selects the image
    private var chooseButton = UIButton()

    /// Image passed to the edit screen.
    private var imageToEdit: UIImage?
    /// Rectangular area identifying the crop region.
    private var cropRect = CGRect()

    /// Session for captureing a still image.
    private var session: AVCaptureSession?
    /// Holds the still image from the camera
    private var stillImageOutput: AVCaptureStillImageOutput?
    /// This class proxy's for the UIImagePickerController.
    private var imagePicker = UIImagePickerController()

    // MARK: - Life Cycle

    public override func viewDidLoad() {
        super.viewDidLoad()

        createSubviews()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        positionImageView()
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - Public Methods

    /// Presents a screen to resize and position the passed image within a circular crop region.
    ///
    /// - Parameters:
    ///     - vc: The view controller to present the edit screen from.
    ///     - image: The image to edit.
    public func presentEditScreen(_ vc: UIViewController, with image: UIImage) {
        isPresentingCamera = false
        isDisplayFromPicker = isPresentingCamera
        imageToEdit = image
        presentingVC = vc
        modalPresentationStyle = .fullScreen

        presentingVC?.present(self, animated: true, completion: nil)
    }

    /// Presents the sequnence of screens to select an image from the device's photo library.
    ///
    /// - Parameter vc: The view controller to present the library selection screen from.
    public func select(fromPhotoLibrary vc: UIViewController) {
        imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.allowsEditing = false
        imagePicker.modalPresentationStyle = .fullScreen
        isDisplayFromPicker = true
        presentingVC = vc;
        imagePicker.delegate = self

        presentingVC?.present(imagePicker, animated: true, completion: nil)
    }

    /// Presents the camera for positioning a scene and acquiring the image.
    ///
    /// - Parameter vc: The view controller to present the camera from.
    public func select(fromCamera vc: UIViewController) {
        isPresentingCamera = true
        // camera = [[MMSCameraViewController alloc] initWithNibName:nil bundle:nil];
        // camera.delegate = self
        presentingVC = vc

        // presentingVC?.present(camera, animated: true, completion: nil)
    }

    // MARK: - Selector Methods

    /// Called when the user is finished with moving and scaling the image to select it as final.  It crops the image and sends the information to the delegate.
    ///
    /// - Parameter sender: The button view tapped.
    @objc private func chooseAction(_ sender: UIButton) {

        var cropOrigin: CGPoint = .zero

        didChooseImage = true

        // Compute the crop rectangle based on the screens dimensions.
        cropOrigin.x = trunc(scrollView.contentOffset.x + scrollView.contentInset.left)
        cropOrigin.y = trunc(scrollView.contentOffset.y + scrollView.contentInset.top);

        let screenCropRect = CGRect(x: cropOrigin.x, y: cropOrigin.y, width: cropRect.size.width, height: cropRect.size.height)

        if let image = imageView.image, let croppedImage = image.cropRectangle(cropArea: screenCropRect, inFrame: scrollView.contentSize) {
            // Transpose the crop rectangle from the screen dimensions to the actual image dimensions.
            let imageCropRect = croppedImage.transposeCropRect(screenCropRect,
                                                               fromBound: CGRect(x: 0,
                                                                                 y: 0,
                                                                                 width: scrollView.contentSize.width,
                                                                                 height: scrollView.contentSize.height),
                                                               toBound: CGRect(x: 0,
                                                                               y: 0,
                                                                               width: image.size.width,
                                                                               height: image.size.height))
            // Create the dictionary properties to pass to the delegate.
            let info: [UIImagePickerController.InfoKey: Any] = [.editedImage: image,
                                                                .originalImage: imageView.image as Any,
                                                                .mediaType: [kUTTypeImage],
                                                                .cropRect: NSValue(cgRect: imageCropRect)]

            delegate?.afImagePickerController(self, didFinishPickingMediaWithInfo: info)
        }
    }

    /// The user has decided to snap another photo if presenting the camera, to choose another image from the album if presenting the album, or to exit the move and scale when only using it to crop an image.
    ///
    /// - Parameter sender: The button view tapped
    @objc private func cancelAction(_ sender: UIButton) {
        if isDisplayFromPicker {
            imagePicker.popViewController(animated: false)
        } else if isPresentingCamera {
            dismiss(animated: false, completion: nil)
        } else {
            delegate?.afImagePickerControllerDidCancel(self)
        }
    }

    private func editImage(_ image: UIImage) {
        imageToEdit = image
        modalPresentationStyle = .fullScreen

        // [camera presentViewController:self animated:YES completion:nil];
    }
}

// MARK: - View Setup and Initalization
extension AFProfileImagePicker {
    /// Positions the image view to fit within the center of the screen.
    private func positionImageView() {
        // Create the scrollView to fit within the physical screen size.
        let screenRect = UIScreen.main.bounds // Get the device physical screen dimensions.

        imageView.image = imageToEdit

        // Calculate the frame  of the image rectangle.  Depending on the orientation of the image and screen and the image's aspect ratio, either the height will fill the screen or the width. The image view is centered on the screen.  Either the height will fill the screen or the width. The dimension sized less than the enclosing rectangle will have equal insets above and below or left and right such that the image when unzooming can be positioned at the top bounder of the circle.
        if let image = imageView.image {
            let imageSize = UIImage.scale(image.size, to: screenRect.size)
            let imageRect = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
            imageView.frame = imageRect

            // Compute crop rectangle.
            cropRect = centerSquareRect(inRect: screenRect.size,
                                        withInsets: UIEdgeInsets(top: overlayInset,
                                                                 left: overlayInset,
                                                                 bottom: overlayInset,
                                                                 right: overlayInset))

            // Compute the scrollView's insets to center the crop rect on the screen and so that the image can be scrolled to the edges of the crop rectangle.
            let insets = insetsForImage(imageSize, withFrame: cropRect.size, inView: screenRect.size)
            scrollView.contentInset = insets
            scrollView.contentSize = imageRect.size
            scrollView.contentOffset = centerRect(imageRect, inside: screenRect)
        }
    }

    /// Creates and positions the subviews to present functionality for moving and scaling an image having a circle overlay by default. It places the title, "Move and Scale" centered at the top of the screen.  A cancel button at the lower left corner and a choose button at the lower right corner.
    private func createSubviews() {
        // Create the scrollView to fit within the physical screen size
        let screenRect = UIScreen.main.bounds // Get the device physical screen dimensions

        scrollView = UIScrollView(frame: screenRect)
        scrollView.backgroundColor = backgroundColor
        scrollView.delegate = self
        scrollView.minimumZoomScale = minimumZoomScale // Content cannot shrink.
        scrollView.maximumZoomScale = maximumZoomScale // Content can grow 10x original size.

        view.backgroundColor = backgroundColor
        // Resize the bottom view (z-order) to fit within the screen size and position it at the top left corner.
        view.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.width)
        view.addSubview(scrollView)

        // Create the image view with the image.
        imageView = UIImageView(image: imageToEdit)
        imageView.contentMode = .scaleToFill
        scrollView.addSubview(imageView)

        // Create the overlay screen positioned over the entire screen having a square positioned at the center of the screen. The square side length is either the width or height of the screen size, whichever is smaller.  It's inset by 10 pixels. Inside the square a circle is drawn to reveal the part of the image that will display in a circlewhen croped to the square's dimensions.
        // Compute crop rectangle.
        cropRect = centerSquareRect(inRect: screenRect.size,
                                    withInsets: UIEdgeInsets(top: overlayInset,
                                                             left: overlayInset,
                                                             bottom: overlayInset,
                                                             right: overlayInset))

        overlayView = UIScrollView(frame: screenRect)
        overlayView.isUserInteractionEnabled = false

        let overlayLayer = createOverlay(cropRect, bounds: screenRect)
        overlayView.layer.addSublayer(overlayLayer)

        view.addSubview(overlayView)

        // Add title, "Move and Scale" positioned at the top center of the screen.
        titleLabel = addTitleLabel(view)
        // Position the cancel button at the bottom left corner of the screen.
        cancelButton = addCancelButton(view, action: #selector(cancelAction(_:)))
        // Position the choose button at the bottom right corner of the screen.
        chooseButton = addChooseButton(view, action: #selector(chooseAction(_:)))
    }

    /// Adds the "Move and Scale" title centered at the top of the parent view.
    ///
    /// - Parameter parentView: The view to add the title to.
    ///
    /// - Returns: The label view added.
    private func addTitleLabel(_ parentView: UIView) -> UILabel {
        // Define constants to create and position the title in the view.
        let titleFrame = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 27.0)
        let topSpace: CGFloat = 25.0

        let label = UILabel(frame: titleFrame)
        label.text = localizedString("Edit.title", comment: "Localized edit tite")
        label.textColor = foregroundColor
        parentView.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false

        // Center the title in the view and position it a short distance from the top.
        if #available(iOS 11.0, *) {
            // iPhone X, et al, support using iOS11 Safe Area Layout Guide mechanism.
            label.centerXAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.centerXAnchor).isActive = true
            label.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.topAnchor, constant: topSpace).isActive = true
        } else {
            label.centerXAnchor.constraint(equalTo: parentView.centerXAnchor).isActive = true
            label.topAnchor.constraint(equalTo: parentView.topAnchor, constant: topSpace).isActive = true
        }

        return label
    }

    /// Adds the button with the title "Cancel" position at the bottom left corner of the parent view.
    ///
    /// - Parameters:
    ///   - parentView: The view to add the button to.
    ///   - action: The method to call on the `UIControlEventTouUpInside` event.
    ///
    /// - Returns: The button view added
    private func addCancelButton(_ parentView: UIView, action: Selector) -> UIButton {
        // Define constants to create and position the choose button on the bottom left corner of the parent view.
        let cancelFrame = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 27.0)
        let cancelLeftSpace: CGFloat = 25.0
        let cancelBottomSpace: CGFloat = 50.0

        let button = UIButton(type: .system)
        button.frame = cancelFrame

        // The button has a different title depending on whether it is displaying from the camera or the photo album picker and edit image.
        let buttonTitle = isPresentingCamera ? localizedString("Button.cancel.photoFromCamera", comment: "Local cancel photo") : localizedString("Button.cancel.photoFromPicker", comment: "Local cancel picker")
        button.setTitle(buttonTitle, for: .normal)

        button.setTitleColor(foregroundColor, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        parentView.addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false

        // Anchor the cancel button to the bottom left corner of the parent view.
        if #available(iOS 11.0, *) {
            // iPhone X, et al, support using iOS11 Safe Area Layout Guide mechanism.
            button.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: -cancelBottomSpace).isActive = true
            button.leftAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leftAnchor, constant: cancelLeftSpace).isActive = true
        } else {
            button.topAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -cancelBottomSpace).isActive = true
            button.leftAnchor.constraint(equalTo: parentView.leftAnchor, constant: cancelLeftSpace).isActive = true
        }

        return button
    }

    /// Adds the button with the title "Choose" position at the bottom right corner of the parent view.
    ///
    /// - Parameters:
    ///   - parentView: The view to add the button to.
    ///   - action: The method to call on the `UIControlEventTouUpInside` event.
    ///
    /// - Returns: The button view added
    private func addChooseButton(_ parentView: UIView, action: Selector) -> UIButton {
        // Define constants to create and position the choose button on the bottom left corner of the parent view.
        let cancelFrame = CGRect(x: 0.0, y: 0.0, width: 75.0, height: 27.0)
        let cancelLeftSpace: CGFloat = 25.0
        let cancelBottomSpace: CGFloat = 50.0

        let button = UIButton(type: .system)
        button.frame = cancelFrame

        // The button has a different title depending on whether it is displaying from the camera or the photo album picker and edit image.
        let buttonTitle = isPresentingCamera ? localizedString("Button.choose.photoFromCamera", comment: "Local use photo") : localizedString("Button.choose.photoFromPicker", comment: "Local use picker")
        button.setTitle(buttonTitle, for: .normal)

        button.setTitleColor(foregroundColor, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        parentView.addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false

        // Anchor the cancel button to the bottom left corner of the parent view.
        if #available(iOS 11.0, *) {
            // iPhone X, et al, support using iOS11 Safe Area Layout Guide mechanism.
            button.topAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: -cancelBottomSpace).isActive = true
            button.leftAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leftAnchor, constant: cancelLeftSpace).isActive = true
        } else {
            button.topAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -cancelBottomSpace).isActive = true
            button.leftAnchor.constraint(equalTo: parentView.leftAnchor, constant: cancelLeftSpace).isActive = true
        }

        return button
    }

    // TODO:
    //    - (void)cameraDidCaptureStillImage:(UIImage *)image camera:(MMSCameraViewController *)cameraController {
    //
    //    [self editImage:image];
    //    }
}

// MARK: - Helper Methods
extension AFProfileImagePicker {
    /// Returns a localized string based on the key.
    ///
    /// - Parameters:
    ///   - key: The identifier for the string.
    ///   - comment: The help text for the key.
    ///
    /// - Returns: Returns the localized string identified by the key.
    private func localizedString(_ key: String, comment: String) -> String {
        return NSLocalizedString(key, tableName: "Localized", bundle: Bundle(for: AFProfileImagePicker.self), comment: comment)
    }

    /// Retuns a rectangle's origin to position the inside rectangle centered within the enclosing one.
    ///
    /// - Parameters:
    ///   - insideRect: The inside rectangle.
    ///   - outsideRect: The rectangle enclosing the inside rectangle.
    ///
    /// - Returns: Inside rectangle's origin to position it centered.
    private func centerRect(_ insideRect: CGRect, inside outsideRect: CGRect) -> CGPoint {
        var upperLeft: CGPoint = .zero

        // Calculate the origin's y coordinate.
        if insideRect.size.height >= outsideRect.size.height {
            upperLeft.y = round((insideRect.size.height - outsideRect.size.height) / 2)
        } else {
            upperLeft.y = -round((outsideRect.size.height - insideRect.size.height) / 2)
        }

        // Calculate the origin's x coordinate.
        if insideRect.size.width >= outsideRect.size.width {
            upperLeft.x = round((insideRect.size.width - outsideRect.size.width) / 2)
        } else {
            upperLeft.x = -round((outsideRect.size.width - insideRect.size.width) / 2)
        }

        return upperLeft
    }

    /// Creates a square with the shortest input dimensions less the insets, and positions the x and y coordinates such that it's center is the same center as would be the rectangle created from the input size and its origin at (0,0).
    ///
    /// - Parameters:
    ///   - layerSize: The size of the layer to create the centered rectangle.
    ///   - insets: The rectangle's insets.
    ///
    /// - Returns: The centered rectangle.
    private func centerSquareRect(inRect layerSize: CGSize, withInsets insets: UIEdgeInsets) -> CGRect {
        var rect: CGRect = .zero

        var length: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0

        // If width is greater than height, swap the height and the width

        if layerSize.height < layerSize.width {
            length = layerSize.height
            x = (layerSize.width / 2 - layerSize.height / 2) + insets.left
            y = insets.top
        } else {
            length = layerSize.width
            x = insets.left
            y = (layerSize.height / 2 - layerSize.width / 2) + insets.top
        }

        rect = CGRect(x: x, y: y, width: length - insets.right - insets.left, height: length - insets.bottom - insets.top)
        return rect
    }

    /// The overlay is the transparent view with the clear center to show how the image will appear when cropped. inBounds is the inside transparent crop region.  outBounds is the region that falls outside the inbound region and displays what's beneath it with dark transparency.
    ///
    /// - Parameters:
    ///   - inBounds: The inside transparent crop rectangle.
    ///   - outBounds: The area outside inbounds.  In this solution it's always the screen dimensions.
    ///
    /// - Returns: The shape layer with a transparent circle and a darker region outside
    private func createOverlay(_ inBounds: CGRect, bounds outBounds: CGRect) -> CAShapeLayer {
        // Create the circle so that it's diameter is the screen width and its center is at the intersection of the horizontal and vertical centers

        let circPath = UIBezierPath(ovalIn: inBounds)

        // Create a rectangular path to enclose the circular path within the bounds of the passed in layer size.
        let rectPath = UIBezierPath(roundedRect: outBounds, cornerRadius: 0)
        rectPath.append(circPath)

        // Add the circle path within the rectangular path to the shape layer.
        let rectLayer = CAShapeLayer()
        rectLayer.path = rectPath.cgPath
        rectLayer.fillRule = .evenOdd
        rectLayer.fillColor = backgroundColor.cgColor
        rectLayer.opacity = Float(overlayOpacity)

        return rectLayer
    }

    /// The goal of this routine is to calculate the insets so that the top and bottom of the image can align with the top and bottom of the frame when it is scrolled within the view.
    ///
    /// - Parameters:
    ///   - imageSize: Height and width of the image.
    ///   - frameSize: Size of the region where the image will be cropped to.
    ///   - viewSize: Size of the view where the image will display.
    private func insetsForImage(_ imageSize: CGSize, withFrame frameSize: CGSize, inView viewSize: CGSize) -> UIEdgeInsets {
        var inset: UIEdgeInsets = .zero
        var deltaInsets: UIEdgeInsets = .zero
        var insideSize = frameSize

        // Compute the delta top and bottom inset if image height is less than the frame.
        if imageSize.height < frameSize.height {
            insideSize.height = imageSize.height

            deltaInsets.bottom = trunc((frameSize.height - insideSize.height) / 2)
            deltaInsets.top = deltaInsets.bottom
        }

        // Compute the delta left and right inset if image width is less than the frame.
        if imageSize.width < frameSize.width {
            insideSize.width = imageSize.width
            deltaInsets.right = trunc((frameSize.width - insideSize.width) / 2)
            deltaInsets.left = deltaInsets.right
        }

        // Compute the inset by adding the image inset with respect to the frame to the inset of the frame with respect to the view.
        inset.top = trunc(((viewSize.height - insideSize.height) / 2) + deltaInsets.top)
        inset.bottom = inset.top

        inset.right = trunc(((viewSize.width - insideSize.width) / 2) + deltaInsets.left)
        inset.left = inset.right

        return inset
    }
}

// MARK: - UIScrollViewDelegate
extension AFProfileImagePicker: UIScrollViewDelegate {
    /// The imageView is the view for zooming the scroll view.
    ///
    /// - Parameter scrollView: The scroll view with the request.
    ///
    /// - Returns: The image view
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    /// Adjusts the scroll view's insets as the view enlarges.  As the scale enlarges the image, the insets shrink so that the edges do not move beyond the corresponding edge of the image mask when the it is scrolled.
    ///
    /// - Parameters:
    ///   - scrollView: The scroll view.
    ///   - view: The view that was zoomed.
    ///   - scale: The scale factor
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        let insets = insetsForImage(scrollView.contentSize, withFrame: cropRect.size, inView: UIScreen.main.bounds.size)
        scrollView.contentInset = insets
    }
}

// MARK: - UIImagePickerControllerDelegate
extension AFProfileImagePicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    /// Presents the move and scale screen with the selected image.
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageToEdit = info[.originalImage] as? UIImage
        modalPresentationStyle = .fullScreen

        imagePicker.setNavigationBarHidden(true, animated: true)
        imagePicker.pushViewController(self, animated: false)
    }

    /// This routine calls the equivalent of this class's custom delegate method.
    ///
    /// - Parameter picker: The image picker controller.
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.afImagePickerControllerDidCancel(self)
    }
}
