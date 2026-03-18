import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
  private let appGroupSuiteName = "group.com.rechef.app"
  private let tokenKey = "firebase_id_token"
  private let apiBaseUrlKey = "api_base_url"
  private let parseEndpoint = "/api/contents/parse"
  private let maxImageBytes = 8 * 1024 * 1024

  private let titleLabel = UILabel()
  private let detailLabel = UILabel()
  private let importButton = UIButton(type: .system)
  private let activityIndicator = UIActivityIndicatorView(style: .medium)

  private var extractedUrl: String?
  private var extractedImageBase64: String?
  private var isSubmitting = false

  override func viewDidLoad() {
    super.viewDidLoad()
    configureUI()
    extractSharedContent()
  }

  private func configureUI() {
    view.backgroundColor = .systemBackground

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = "Import to Rechef"
    titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
    titleLabel.textAlignment = .center

    detailLabel.translatesAutoresizingMaskIntoConstraints = false
    detailLabel.text = "Reading shared content..."
    detailLabel.font = .systemFont(ofSize: 14)
    detailLabel.textColor = .secondaryLabel
    detailLabel.textAlignment = .center
    detailLabel.numberOfLines = 0

    importButton.translatesAutoresizingMaskIntoConstraints = false
    importButton.setTitle("Import", for: .normal)
    importButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
    importButton.addTarget(self, action: #selector(handleImportTapped), for: .touchUpInside)
    importButton.isEnabled = false

    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    activityIndicator.hidesWhenStopped = true

    view.addSubview(titleLabel)
    view.addSubview(detailLabel)
    view.addSubview(importButton)
    view.addSubview(activityIndicator)

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
      titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
      detailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      detailLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      importButton.topAnchor.constraint(equalTo: detailLabel.bottomAnchor, constant: 24),
      importButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

      activityIndicator.topAnchor.constraint(equalTo: importButton.bottomAnchor, constant: 12),
      activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    ])
  }

  private func extractSharedContent() {
    guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
      setReadyState(hasContent: false, message: "No content found.")
      return
    }
    Task {
      let content = await readContent(from: items)
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        self.extractedUrl = content.url
        self.extractedImageBase64 = content.imageBase64
        if let url = content.url {
          self.setReadyState(hasContent: true, message: "Ready to import:\n\(url)")
        } else if content.imageBase64 != nil {
          self.setReadyState(hasContent: true, message: "Ready to import shared image.")
        } else {
          self.setReadyState(hasContent: false, message: "Could not read a URL or image from this share.")
        }
      }
    }
  }

  private func setReadyState(hasContent: Bool, message: String) {
    detailLabel.text = message
    importButton.isEnabled = hasContent && !isSubmitting
  }

  @objc
  private func handleImportTapped() {
    if isSubmitting { return }
    guard let defaults = UserDefaults(suiteName: appGroupSuiteName) else {
      setReadyState(hasContent: true, message: "App configuration unavailable. Open Rechef and try again.")
      return
    }
    guard let token = defaults.string(forKey: tokenKey), !token.isEmpty else {
      setReadyState(hasContent: true, message: "Open Rechef and sign in first.")
      return
    }
    guard let apiBaseUrl = defaults.string(forKey: apiBaseUrlKey), !apiBaseUrl.isEmpty else {
      setReadyState(hasContent: true, message: "Open Rechef once to sync app settings, then try again.")
      return
    }

    let payload = buildPayload()
    guard payload != nil else {
      setReadyState(hasContent: false, message: "No valid URL or image to import.")
      return
    }

    isSubmitting = true
    importButton.isEnabled = false
    detailLabel.text = "Sending..."
    activityIndicator.startAnimating()
    submitImport(apiBaseUrl: apiBaseUrl, token: token, payload: payload!)
  }

  private func buildPayload() -> [String: Any]? {
    if let url = extractedUrl {
      return ["url": url]
    }
    if let imageBase64 = extractedImageBase64 {
      return ["imageBase64": imageBase64]
    }
    return nil
  }

  private func submitImport(apiBaseUrl: String, token: String, payload: [String: Any]) {
    let endpoint = apiBaseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + parseEndpoint
    guard let url = URL(string: endpoint) else {
      finishWithError("Invalid API URL. Open Rechef and try again.")
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.timeoutInterval = 15
    request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

    URLSession.shared.dataTask(with: request) { [weak self] _, response, _ in
      DispatchQueue.main.async {
        guard let self else { return }
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        if statusCode == 202 {
          self.detailLabel.text = "Done - open Rechef to view when ready."
          self.activityIndicator.stopAnimating()
          self.completeExtension(after: 0.5)
        } else {
          self.finishWithError("Import failed. Try again in Rechef.")
        }
      }
    }.resume()
  }

  private func finishWithError(_ message: String) {
    isSubmitting = false
    activityIndicator.stopAnimating()
    importButton.isEnabled = true
    detailLabel.text = message
  }

  private func completeExtension(after delay: TimeInterval) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
      self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
  }

  private func readContent(from items: [NSExtensionItem]) async -> (url: String?, imageBase64: String?) {
    for item in items {
      guard let attachments = item.attachments else { continue }
      for provider in attachments {
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
           let url = await loadURL(from: provider) {
          return (url, nil)
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
           let text = await loadText(from: provider),
           let extracted = extractFirstHTTPURL(from: text) {
          return (extracted, nil)
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier),
           let imageBase64 = await loadImageBase64(from: provider) {
          return (nil, imageBase64)
        }
      }
    }
    return (nil, nil)
  }

  private func loadURL(from provider: NSItemProvider) async -> String? {
    await withCheckedContinuation { continuation in
      provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
        if let url = item as? URL, ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
          continuation.resume(returning: url.absoluteString)
          return
        }
        if let str = item as? String, let extracted = self.extractFirstHTTPURL(from: str) {
          continuation.resume(returning: extracted)
          return
        }
        continuation.resume(returning: nil)
      }
    }
  }

  private func loadText(from provider: NSItemProvider) async -> String? {
    await withCheckedContinuation { continuation in
      provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
        if let text = item as? String {
          continuation.resume(returning: text)
          return
        }
        if let url = item as? URL {
          continuation.resume(returning: url.absoluteString)
          return
        }
        continuation.resume(returning: nil)
      }
    }
  }

  private func loadImageBase64(from provider: NSItemProvider) async -> String? {
    await withCheckedContinuation { continuation in
      provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
        if let imageURL = item as? URL,
           let data = try? Data(contentsOf: imageURL),
           data.count <= self.maxImageBytes {
          continuation.resume(returning: data.base64EncodedString())
          return
        }
        if let image = item as? UIImage,
           let data = image.jpegData(compressionQuality: 0.9),
           data.count <= self.maxImageBytes {
          continuation.resume(returning: data.base64EncodedString())
          return
        }
        if let data = item as? Data, data.count <= self.maxImageBytes {
          continuation.resume(returning: data.base64EncodedString())
          return
        }
        continuation.resume(returning: nil)
      }
    }
  }

  private func extractFirstHTTPURL(from text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if let direct = URL(string: trimmed),
       let scheme = direct.scheme?.lowercased(),
       scheme == "http" || scheme == "https" {
      return trimmed
    }
    let pattern = #"https?://[^\s]+"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
      return nil
    }
    let range = NSRange(location: 0, length: text.utf16.count)
    guard let match = regex.firstMatch(in: text, options: [], range: range),
          let swiftRange = Range(match.range, in: text) else {
      return nil
    }
    return String(text[swiftRange])
  }
}
