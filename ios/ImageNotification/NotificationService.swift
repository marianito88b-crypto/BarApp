import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {
            
            // 1. Buscamos la imagen en fcm_options O en data (más robusto)
            var urlString: String? = nil
            
            // Intento A: fcm_options
            if let fcmOptions = bestAttemptContent.userInfo["fcm_options"] as? [String: Any],
               let image = fcmOptions["image"] as? String {
                urlString = image
            }
            
            // Intento B: data payload (backup)
            if urlString == nil, let image = bestAttemptContent.userInfo["attachment_url"] as? String {
                urlString = image
            }

            guard let finalUrlString = urlString, let url = URL(string: finalUrlString) else {
                contentHandler(bestAttemptContent)
                return
            }

            // 2. Descargar imagen
            URLSession.shared.downloadTask(with: url) { (location, response, error) in
                if let location = location {
                    // 3. CORRECCIÓN CRÍTICA: Forzamos un nombre de archivo limpio (.jpg)
                    // Ignoramos el nombre original que trae tokens raros de Firebase
                    let tmpDirectory = NSTemporaryDirectory()
                    let tmpFile = "file://".appending(tmpDirectory).appending("temp_notif_image.jpg")
                    let tmpUrl = URL(string: tmpFile)!
                    
                    // Si ya existe uno viejo, lo borramos
                    try? FileManager.default.removeItem(at: tmpUrl)
                    try? FileManager.default.moveItem(at: location, to: tmpUrl)
                    
                    // 4. Adjuntar
                    if let attachment = try? UNNotificationAttachment(identifier: "image", url: tmpUrl, options: nil) {
                        bestAttemptContent.attachments = [attachment]
                    }
                }
                contentHandler(bestAttemptContent)
            }.resume()
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
