import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
  private let appGroupSuiteName = "group.com.rechef.app"
  private let tokenKey = "firebase_id_token"
  private let apiBaseUrlKey = "api_base_url"
  private let parseEndpoint = "/api/contents/parse"
  private let maxImageBytes = 8 * 1024 * 1024

  private let logoImageView = UIImageView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let statusLabel = UILabel()
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

    logoImageView.translatesAutoresizingMaskIntoConstraints = false
    logoImageView.contentMode = .scaleAspectFit
    logoImageView.image = logoImage()

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = "Importing recipe"
    titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
    titleLabel.textAlignment = .center

    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
    subtitleLabel.text = "We'll notify you when we're done."
    subtitleLabel.font = .systemFont(ofSize: 14)
    subtitleLabel.textColor = .secondaryLabel
    subtitleLabel.textAlignment = .center
    subtitleLabel.numberOfLines = 0

    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
    statusLabel.textColor = .secondaryLabel
    statusLabel.textAlignment = .center
    statusLabel.numberOfLines = 3

    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    activityIndicator.hidesWhenStopped = true

    view.addSubview(logoImageView)
    view.addSubview(titleLabel)
    view.addSubview(subtitleLabel)
    view.addSubview(activityIndicator)
    view.addSubview(statusLabel)

    NSLayoutConstraint.activate([
      logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      logoImageView.heightAnchor.constraint(equalToConstant: 42),
      logoImageView.widthAnchor.constraint(equalToConstant: 42),

      titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

      activityIndicator.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
      activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),

      statusLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 12),
      statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
    ])
  }

  private func extractSharedContent() {
    guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
      showErrorThenClose("No content found.")
      return
    }
    activityIndicator.startAnimating()
    Task {
      let content = await readContent(from: items)
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        self.extractedUrl = content.url
        self.extractedImageBase64 = content.imageBase64
        self.tryStartImport()
      }
    }
  }

  private func tryStartImport() {
    guard let payload = buildPayload() else {
      showErrorThenClose("Could not read a URL or image from this share.")
      return
    }
    guard let defaults = UserDefaults(suiteName: appGroupSuiteName) else {
      showErrorThenClose("App configuration unavailable. Open Rechef and try again.")
      return
    }
    guard let token = defaults.string(forKey: tokenKey), !token.isEmpty else {
      showErrorThenClose("Open Rechef and sign in first.")
      return
    }
    guard let apiBaseUrl = defaults.string(forKey: apiBaseUrlKey), !apiBaseUrl.isEmpty else {
      showErrorThenClose("Open Rechef once to sync settings, then try again.")
      return
    }

    isSubmitting = true
    submitImport(apiBaseUrl: apiBaseUrl, token: token, payload: payload)
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
      showErrorThenClose("Invalid API URL. Open Rechef and try again.")
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
          self.activityIndicator.stopAnimating()
          self.statusLabel.text = nil
          self.completeExtension(after: 0.25)
        } else {
          self.showErrorThenClose("Import failed. Try again in Rechef.")
        }
      }
    }.resume()
  }

  private func showErrorThenClose(_ message: String) {
    activityIndicator.stopAnimating()
    statusLabel.text = message
    isSubmitting = false
    completeExtension(after: 2.2)
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

  private func logoImage() -> UIImage? {
    if let extensionIcon = appIconImage(from: Bundle.main) {
      return extensionIcon
    }
    if let appBundle = containingAppBundle(),
       let appIcon = appIconImage(from: appBundle) {
      return appIcon
    }
    return nil
  }

  private func containingAppBundle() -> Bundle? {
    let pluginsURL = Bundle.main.bundleURL.deletingLastPathComponent()
    let appURL = pluginsURL.deletingLastPathComponent()
    return Bundle(url: appURL)
  }

  private func appIconImage(from bundle: Bundle) -> UIImage? {
    let iconNames = iconFileNames(from: bundle)
    for name in iconNames.reversed() {
      if let image = UIImage(named: name, in: bundle, compatibleWith: nil) {
        return image
      }
    }
    return nil
  }

  private func iconFileNames(from bundle: Bundle) -> [String] {
    guard let icons = bundle.infoDictionary?["CFBundleIcons"] as? [String: Any],
          let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
          let files = primary["CFBundleIconFiles"] as? [String] else {
      return []
    }
    return files
  }
}
