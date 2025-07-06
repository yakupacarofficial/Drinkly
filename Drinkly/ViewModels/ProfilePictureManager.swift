//
//  ProfilePictureManager.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI
import PhotosUI
import UIKit
import AVFoundation

/// Manages profile picture functionality including image picker and storage
@MainActor
class ProfilePictureManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var profileImage: UIImage?
    @Published var isImagePickerPresented = false
    @Published var showingImageOptions = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingError = false
    @Published var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let imageKey = "drinkly_profile_picture"
    
    // MARK: - Initialization
    init() {
        loadProfileImage()
    }
    
    // MARK: - Public Methods
    
    /// Show image picker options (camera or photo library)
    func showImageOptions() {
        showingImageOptions = true
    }
    
    /// Select camera as image source
    func selectCamera() {
        HapticFeedbackHelper.shared.trigger()
        
        // Check if camera is available
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            // Check camera authorization
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                imagePickerSourceType = .camera
                isImagePickerPresented = true
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        if granted {
                            self?.imagePickerSourceType = .camera
                            self?.isImagePickerPresented = true
                        } else {
                            self?.showCameraPermissionAlert()
                        }
                    }
                }
            case .denied, .restricted:
                showCameraPermissionAlert()
            @unknown default:
                showCameraPermissionAlert()
            }
        } else {
            // Camera not available, use photo library
            imagePickerSourceType = .photoLibrary
            isImagePickerPresented = true
        }
    }
    
    /// Select photo library as image source
    func selectPhotoLibrary() {
        HapticFeedbackHelper.shared.trigger()
        imagePickerSourceType = .photoLibrary
        isImagePickerPresented = true
    }
    
    /// Show camera permission alert
    private func showCameraPermissionAlert() {
        errorMessage = "Camera access is required to take photos. Please enable camera access in Settings."
        showingError = true
    }
    
    /// Load profile image from storage
    func loadProfileImage() {
        guard let imageData = userDefaults.data(forKey: imageKey) else { return }
        
        if let image = UIImage(data: imageData) {
            profileImage = image
        }
    }
    
    /// Save profile image to storage
    func saveProfileImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process image"
            showingError = true
            return
        }
        
        userDefaults.set(imageData, forKey: imageKey)
        profileImage = image
    }
    
    /// Remove profile image
    func removeProfileImage() {
        userDefaults.removeObject(forKey: imageKey)
        profileImage = nil
    }
    
    /// Process selected image with validation and compression
    func processSelectedImage(_ image: UIImage) {
        isLoading = true
        
        // Validate image size
        let maxSize: CGFloat = 1024
        let processedImage: UIImage
        
        if image.size.width > maxSize || image.size.height > maxSize {
            processedImage = image.resized(to: CGSize(width: maxSize, height: maxSize))
        } else {
            processedImage = image
        }
        
        // Save processed image
        saveProfileImage(processedImage)
        isLoading = false
    }
    
    /// Get profile image with fallback
    func getProfileImage() -> UIImage? {
        return profileImage
    }
    
    /// Check if profile image exists
    var hasProfileImage: Bool {
        return profileImage != nil
    }
}

// MARK: - UIImage Extension for Resizing
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Image Picker View
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Profile Picture View
struct ProfilePictureView: View {
    @EnvironmentObject var profilePictureManager: ProfilePictureManager
    let size: CGFloat
    let showEditButton: Bool
    
    init(size: CGFloat = 60, showEditButton: Bool = false) {
        self.size = size
        self.showEditButton = showEditButton
    }
    
    var body: some View {
        ZStack {
            if let image = profilePictureManager.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue, lineWidth: 2))
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.4))
                            .foregroundColor(.gray)
                    )
            }
            
            if showEditButton {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            profilePictureManager.showImageOptions()
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $profilePictureManager.isImagePickerPresented) {
            ImagePicker(selectedImage: $profilePictureManager.profileImage, isPresented: $profilePictureManager.isImagePickerPresented, sourceType: profilePictureManager.imagePickerSourceType)
                .onDisappear {
                    if let image = profilePictureManager.profileImage {
                        profilePictureManager.processSelectedImage(image)
                    }
                }
        }
        .actionSheet(isPresented: $profilePictureManager.showingImageOptions) {
            ActionSheet(
                title: Text("Profile Picture"),
                message: Text("Choose an option"),
                buttons: [
                    .default(Text("Camera")) {
                        // Handle camera access
                        profilePictureManager.selectCamera()
                    },
                    .default(Text("Photo Library")) {
                        profilePictureManager.selectPhotoLibrary()
                    },
                    .destructive(Text("Remove")) {
                        profilePictureManager.removeProfileImage()
                    },
                    .cancel()
                ]
            )
        }
        .alert("Error", isPresented: $profilePictureManager.showingError) {
            Button("OK") { }
        } message: {
            Text(profilePictureManager.errorMessage)
        }
    }
}

// MARK: - Preview
#Preview {
    ProfilePictureView(showEditButton: true)
        .environmentObject(ProfilePictureManager())
} 