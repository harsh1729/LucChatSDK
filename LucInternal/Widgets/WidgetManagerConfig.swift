/*
 

 

 
 */

import Foundation

/// Configuration for an integration manager.
/// By default, it uses URLs defined in the app settings but they can be overidden.
@objcMembers
public class WidgetManagerConfig: NSObject, NSCoding {

    /// The URL for the REST api
    public let apiUrl: NSString?
    /// The URL of the integration manager interface
    public let uiUrl: NSString?
    /// The token if the user has been authenticated
    public var scalarToken: NSString?

    public var hasUrls: Bool {
        if apiUrl != nil && uiUrl != nil {
            return true
        } else {
            return false
        }
    }

    public init(apiUrl: NSString?, uiUrl: NSString?) {
        self.apiUrl = apiUrl
        self.uiUrl = uiUrl

        super.init()
    }

    public override convenience init () {
        // Use app settings as default
        let apiUrl = UserDefaults.standard.object(forKey: "integrationsRestUrl") as? NSString
        let uiUrl = UserDefaults.standard.object(forKey: "integrationsUiUrl") as? NSString

        self.init(apiUrl: apiUrl, uiUrl: uiUrl)
    }


    /// MARK: - NSCoding

    enum CodingKeys: String {
        case apiUrl = "apiUrl"
        case uiUrl = "uiUrl"
        case scalarToken = "scalarToken"
    }

    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.apiUrl, forKey: CodingKeys.apiUrl.rawValue)
        aCoder.encode(self.uiUrl, forKey: CodingKeys.uiUrl.rawValue)
        aCoder.encode(self.scalarToken, forKey: CodingKeys.scalarToken.rawValue)
    }

    public convenience required init?(coder aDecoder: NSCoder) {
        let apiUrl = aDecoder.decodeObject(forKey: CodingKeys.apiUrl.rawValue) as? NSString
        let uiUrl = aDecoder.decodeObject(forKey: CodingKeys.uiUrl.rawValue) as? NSString
        let scalarToken = aDecoder.decodeObject(forKey: CodingKeys.scalarToken.rawValue) as? NSString

        self.init(apiUrl: apiUrl, uiUrl: uiUrl)
        self.scalarToken = scalarToken
    }
}
