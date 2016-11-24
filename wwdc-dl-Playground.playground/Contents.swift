
import Foundation

// http://stackoverflow.com/a/26135752/242682
func htmlPage(withURL url: String) -> String? {
    guard let myURL = URL(string: url) else {
        print("Error: \(url) doesn't seem to be a valid URL")
        return nil
    }
    
    do {
        let myHTMLString = try String(contentsOf: myURL)
        return myHTMLString
    } catch let error as NSError {
        print("Error: \(error)")
    }
    return nil
}

// http://stackoverflow.com/a/27880748/242682
func matchesForRegexInText(_ regex: String!, text: String!) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex, options: [])
        let nsString = text as NSString
        let results = regex.matches(in: text,
                                            options: [], range: NSMakeRange(0, nsString.length))
        return results.map { nsString.substring(with: $0.range)}
    } catch let error as NSError {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}

// http://stackoverflow.com/a/30106868/242682
class HttpDownloader {
    class func loadFileSync(_ url: URL, inDirectory directoryString: String?, inYear year: String, completion:(_ path: String?, _ error: NSError?) -> Void) {
        guard let directoryURL = createDirectoryURL(directoryString) else {
            let directory = directoryString ?? "User's Document directory"
            let error = NSError(domain:"Could not access the directory in \(directory)", code:800, userInfo:nil)
            completion(nil, error)
            return
        }

        let wwdcDirectoryUrl = directoryURL.appendingPathComponent("WWDC-\(year)")

        guard createWWDCDirectory(wwdcDirectoryUrl) else {
            let error = NSError(domain:"Cannot create WWDC directory", code:800, userInfo:nil)
            completion(nil, error)
            return
        }

        let destinationUrl = wwdcDirectoryUrl.appendingPathComponent(url.lastPathComponent)

        guard FileManager().fileExists(atPath: destinationUrl.path) == false else {
            let error = NSError(domain:"File already exists", code:800, userInfo:nil)
            completion(destinationUrl.path, error)
            return
        }
        
        // Downloading begins here
        guard let dataFromURL = try? Data(contentsOf: url) else {
            let error = NSError(domain:"Error downloading file", code:800, userInfo:nil)
            completion(destinationUrl.path, error)
            return
        }
        
        if (try? dataFromURL.write(to: destinationUrl, options: [.atomic])) != nil {
            completion(destinationUrl.path, nil)
        } else {
            let error = NSError(domain:"Error saving file", code:800, userInfo:nil)
            completion(destinationUrl.path, error)
        }
    }

    /// Create the NSURL from the string
    class func createDirectoryURL(_ directoryString: String?) -> URL? {
        var directoryURL: URL?
        if let directoryString = directoryString {
            directoryURL = URL(fileURLWithPath: directoryString, isDirectory: true)
        } else {
            // Use user's Document directory
            directoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
        return directoryURL
    }
    
    /// Return true if the WWDC-2016 directory is created/existed for use
    class func createWWDCDirectory(_ directory: URL) -> Bool {
        if FileManager.default.fileExists(atPath: directory.path) == false {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                return true
            } catch let error as NSError {
                print("Error creating WWDC-2016 directory in the directory/Documents: \(error.localizedDescription)")
            }
            return false
        }
        return true
    }
}

func downloadSession(inYear year: String, forSession sessionId: String, wantsPDF: Bool, wantsPDFOnly: Bool, isVideoResolutionHD: Bool, inDirectory directory: String?) {
    print("Processing for Session \(sessionId)..")
    let playPageUrl = "https://developer.apple.com/videos/play/wwdc\(year)/\(sessionId)/"
    guard let playPageHtml = htmlPage(withURL: playPageUrl) else {
        print("Cannot read the HTML page: \(playPageUrl)")
        return
    }
    
    // Examples:
    // http://devstreaming.apple.com/videos/wwdc/2016/802z6j79sd7g5drr7k7/802/802_hd_designing_for_tvos.mp4
    // http://devstreaming.apple.com/videos/wwdc/2016/802z6j79sd7g5drr7k7/802/802_sd_designing_for_tvos.mp4
    // http://devstreaming.apple.com/videos/wwdc/2016/802z6j79sd7g5drr7k7/802/802_designing_for_tvos.pdf
    var regexHD = "http://devstreaming.apple.com/videos/wwdc/\(year)/\(sessionId).*/\(sessionId)/\(sessionId)_hd_.*.mp4"
    var regexSD = "http://devstreaming.apple.com/videos/wwdc/\(year)/\(sessionId).*/\(sessionId)/\(sessionId)_sd_.*.mp4"
    let regexPDF = "http://devstreaming.apple.com/videos/wwdc/\(year)/\(sessionId).*/\(sessionId)/\(sessionId)_.*.pdf"
    
    if year == "2014" {
        // Use .mov istead
        regexHD = "http://devstreaming.apple.com/videos/wwdc/\(year)/\(sessionId).*/\(sessionId)/\(sessionId)_hd_.*.mov"
        regexSD = "http://devstreaming.apple.com/videos/wwdc/\(year)/\(sessionId).*/\(sessionId)/\(sessionId)_sd_.*.mov"
    }
    
    if wantsPDF {
        let matchesPDF = matchesForRegexInText(regexPDF, text: playPageHtml)
        
        if matchesPDF.count > 0 {
            let urlPDF = URL(string: matchesPDF[0])
            if let urlPDF = urlPDF {
                HttpDownloader.loadFileSync(urlPDF, inDirectory: directory, inYear: year, completion: { path, error in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    } else {
                        print("PDF downloaded to: \(path!)")
                    }
                })
            }
        } else {
            print("Cannot find PDF for session")
        }
    }
    
    if wantsPDFOnly == false {
        var urlVideo: URL?
        if isVideoResolutionHD {
            let matchesHD = matchesForRegexInText(regexHD, text: playPageHtml)
            if matchesHD.count > 0 {
                urlVideo = URL(string: matchesHD[0])
            } else {
                print("Cannot find HD Video")
            }
        } else {
            let matchesSD = matchesForRegexInText(regexSD, text: playPageHtml)
            if matchesSD.count > 0 {
                urlVideo = URL(string: matchesSD[0])
            } else {
                print("Cannot find SD Video")
            }
        }

        if let urlVideo = urlVideo {
            HttpDownloader.loadFileSync(urlVideo, inDirectory: directory, inYear: year, completion: { path, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                } else {
                    print("Video downloaded to: \(path!)")
                }
            })
        }
    }
}

func findAllSessionIds(inYear year: String = "2016") -> [String]? {
    let urlString = "https://developer.apple.com/videos/wwdc\(year)/"
    guard let html = htmlPage(withURL: urlString) else {
        print("Cannot read the HTML page: \(urlString)")
        return nil
    }
    
    let regexString = "/videos/play/wwdc\(year)/([0-9]*)/"
    
    do {
        let regex = try NSRegularExpression(pattern: regexString, options: [])
        let nsString = html as NSString
        let results = regex.matches(in: html, options: [], range: NSMakeRange(0, nsString.length))
        
        var sessionids = [String]()
        for result in results {
            let matchedRange = result.rangeAt(1)
            let matchedString = nsString.substring(with: matchedRange)
            sessionids.append(matchedString)
        }
        
        let uniqueIds = Array(Set(sessionids))
        return uniqueIds.sorted { $0 < $1 }
    } catch let error as NSError {
        print("Regex error: \(error.localizedDescription)")
    }
    return nil
}

// Test
//findAllSessionIds() // 2016 by default
//findAllSessionIds(inYear: "2015")


// Sensible defaults
var sessionIds = [String]()  // -s 123,456 or if nil, download all!
var isDownloadAll = false // -a to download all
var isVideoResolutionHD = false // -f HD
var wantsPDFOnly = false // --pdfonly
var wantsPDF = true // --nopdf
var directoryToSaveTo: String? = nil // nil will be user's Documents directory
var year = "2016" // -y 2015

// Processing launch arguments
// http://ericasadun.com/2014/06/12/swift-at-the-command-line/
let arguments = ProcessInfo.processInfo.arguments as [String]
let dashedArguments = arguments.filter({$0.hasPrefix("-")})

for argument : String in dashedArguments {
    let key = argument.substring(from: argument.index(after: argument.startIndex))
    let value = UserDefaults.standard.value(forKey: key) as AnyObject?
    let valueString = value as? String
    // print("    \(argument) \(value)")
    
    if argument == "-d" {
        if let directory = valueString {
            directoryToSaveTo = directory
        }
    }
    
    if argument == "-f" && valueString == "HD" {
        isVideoResolutionHD = true
    }
    
    if argument == "--nopdf" {
        wantsPDF = false
    }
    
    if argument == "--pdfonly" {
        wantsPDFOnly = true
    }
    
    if argument == "-a" {
        isDownloadAll = true
    }

    if argument == "-s" {
        sessionIds = (valueString?.components(separatedBy: ","))!
        isDownloadAll = false
        print("Downloading for sessions: \(sessionIds)")
    }
    
    if argument == "-y" {
        if let yearString = valueString {
            year = yearString
        }
    }
}

if isDownloadAll {
    sessionIds = findAllSessionIds()!
}

for sessionId in sessionIds {
    downloadSession(inYear: year, forSession: sessionId, wantsPDF: wantsPDF, wantsPDFOnly: wantsPDFOnly, isVideoResolutionHD: isVideoResolutionHD, inDirectory: directoryToSaveTo)
}

// Test
//downloadSession(inYear: "2016", forSession: "104", wantsPDF: false, wantsPDFOnly: false, isVideoResolutionHD: false, inDirectory: directoryToSaveTo)
downloadSession(inYear: "2014", forSession: "228", wantsPDF: true, wantsPDFOnly: false, isVideoResolutionHD: true, inDirectory: directoryToSaveTo)

