/// Handles photo messages during conversation flows.
/// Routes photos based on current session state.
struct FlowPhotoHandler: MediaHandler {
    func handle(_ message: Components.Schemas.Message, mediaType: MediaType, context: UpdateContext) async {
        guard mediaType == .photo,
              let user = message.from,
              let photos = message.photo,
              let largestPhoto = photos.last // Telegram sends multiple sizes, last is largest
        else { return }

        let fileId = largestPhoto.file_id

        switch context.state(for: user.id) {
        case .profile(.uploadingPhoto):
            await ProfileFlow.processPhoto(fileId: fileId, message: message, context: context)

        case .profile(.editing(.photo)):
            await ProfileFlow.processEditedPhoto(fileId: fileId, message: message, context: context)

        default:
            break // Not expecting a photo
        }
    }
}
