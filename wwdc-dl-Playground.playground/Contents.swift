
import Foundation

let currentYear = "2022"

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


public extension String {
    /// Return the captured groups of the first matched regex pattern.
    /// This is a simplified method for single regex matching. Use `capturedGroups` for multiple matches.
    func capturedGroupsWithSingleMatch(regex pattern: String) -> [String] {
        let results = capturedGroups(regex: pattern)
        return results.first ?? []
    }

    /// Return array of matches, with array of captured groups.
    /// Inner array are the captured groups, while outer array are the regex matches
    func capturedGroups(regex pattern: String) -> [[String]] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let results = regex.matches(in: self, options: [], range: NSRange(location:0, length: self.count))
            return results.map {
                capturedGroups(of: $0)
            }
        } catch {
            return [[]]
        }
    }

    /// Return array of captured groups as string, from a primitive `NSTextCheckingResult`.
    /// `NSTextCheckingResult` has a perculiar way of storing the matched results:
    /// Index 0 is the range of the whole string matched
    /// Index 1..last are the ranges of the captured groups
    func capturedGroups(of result: NSTextCheckingResult) -> [String] {
        let lastRangeIndex = result.numberOfRanges - 1
        guard lastRangeIndex >= 1 else { return [] }

        var capturedGroups = [String]()
        for i in 1...lastRangeIndex {
            let capturedGroupIndex = result.range(at: i)
            let capturedGroup = (self as NSString).substring(with: capturedGroupIndex)
            capturedGroups.append(capturedGroup)
        }
        return capturedGroups
    }
}

// http://stackoverflow.com/a/30106868/242682
class HttpDownloader {
    class func loadFileSync(_ url: URL, inDirectory directoryString: String?, inYear year: String, filename: String? = nil, completion:(_ path: String?, _ error: NSError?) -> Void) {

        guard let wwdcDirectoryUrl = ensureWwdcDirectoryIsCreated(in: directoryString, year: year) else {
            print("Could not create WWDC directory")
            return
        }

        let destinationUrl: URL
        if let filename = filename {
            destinationUrl = wwdcDirectoryUrl.appendingPathComponent(filename)
        } else {
            destinationUrl = wwdcDirectoryUrl.appendingPathComponent(url.lastPathComponent)
        }

        guard FileManager().fileExists(atPath: destinationUrl.path) == false else {
            let error = NSError(domain:"File already exists", code:800, userInfo:nil)
            completion(destinationUrl.path, error)
            return
        }
        
        do {
            // Downloading begins here
            let dataFromURL = try Data(contentsOf: url)
            try dataFromURL.write(to: destinationUrl, options: [.atomic])
        } catch let error as NSError {
            print("Error downloading/writing \(error)")
            completion(destinationUrl.path, error)
        }
        
    }

}

/// Create the NSURL from the string
func createDirectoryURL(_ directoryString: String?) -> URL? {
    var directoryURL: URL?
    if let directoryString = directoryString {
        directoryURL = URL(fileURLWithPath: directoryString, isDirectory: true)
    } else {
        // Use user's Document directory
        directoryURL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    return directoryURL
}

/// Return true if the WWDC directory is created/existed for use
func createWWDCDirectory(_ directory: URL) -> Bool {
    if FileManager.default.fileExists(atPath: directory.path) == false {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch let error as NSError {
            print("Error creating WWDC directory in the directory/Documents: \(error.localizedDescription)")
        }
        return false
    }
    return true
}

func ensureWwdcDirectoryIsCreated(in directoryString: String?, year: String) -> URL? {
    guard let directoryURL = createDirectoryURL(directoryString) else {
        print("Could not access the directory in \(directoryString ?? "User's Document directory")")
        return nil
    }

    let wwdcDirectoryUrl = directoryURL.appendingPathComponent("WWDC-\(year)")

    guard createWWDCDirectory(wwdcDirectoryUrl) else {
        print("Cannot create WWDC directory")
        return nil
    }

    return wwdcDirectoryUrl
}

func shell(launchPath: String, arguments: [String]) -> String {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = arguments
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String = String(data: data, encoding: .utf8)! as String
    
    return output
}

func downloadWithYoutubeDl(url: String, in directory: String) {
    let _directory = directory
        .replacingOccurrences(of: "%20", with: "-")
        .replacingOccurrences(of: "%E2%80%99", with: "") // ’
        .replacingOccurrences(of: ":", with: "")
        .replacingOccurrences(of: ",", with: "")
        .replacingOccurrences(of: "/", with: "")
    print("Using youtube-dl.. output \(_directory)")
     let result = shell(launchPath: "/usr/local/bin/youtube-dl", arguments: ["-o", "\(_directory)", url])
    print(result)
}

func downloadSession(inYear year: String, forSession sessionId: String, wantsPDF: Bool, wantsPDFOnly: Bool, isVideoResolutionHD: Bool, inDirectory directory: String?, useYoutubeDl: Bool = false) {
    let playPageUrl = "https://developer.apple.com/videos/play/wwdc\(year)/\(sessionId)/"
    print("Processing \(playPageUrl)")

    guard let playPageHtml = htmlPage(withURL: playPageUrl) else {
        print("Error: Cannot read the HTML page")
        return
    }
    
    // Examples:
    // http://devstreaming.apple.com/videos/wwdc/2016/802z6j79sd7g5drr7k7/802/802_hd_designing_for_tvos.mp4
    // http://devstreaming.apple.com/videos/wwdc/2016/802z6j79sd7g5drr7k7/802/802_sd_designing_for_tvos.mp4
    // http://devstreaming.apple.com/videos/wwdc/2016/802z6j79sd7g5drr7k7/802/802_designing_for_tvos.pdf
    var regexHD = "http://devstreaming.apple.com/videos/wwdc/\(year)/\(sessionId).*/\(sessionId)/\(sessionId)_hd_.*.mp4"
    var regexSD = "http://devstreaming.apple.com/videos/wwdc/\(year)/\(sessionId).*/\(sessionId)/\(sessionId)_sd_.*.mp4"
    var regexPDF = "http://devstreaming.apple.com/videos/wwdc/\(year)/\(sessionId).*/\(sessionId)/\(sessionId)_.*.pdf"
    
    let regexHls = "https://devstreaming-cdn.apple.com/videos/wwdc/\(year)/\(sessionId).*/\(sessionId).*.m3u8"
    
    switch year {
    case "2025": fallthrough
    case "2024": fallthrough
    case "2023": fallthrough
    case "2022": fallthrough
	case "2021":
		// "https://devstreaming-cdn.apple.com/videos/wwdc/2021/10233/4/72F4F22E-DDAB-4A58-B049-7AC537198EFC/downloads/wwdc2021-10233_hd.mp4?dl=1"
		regexHD = "https://devstreaming-cdn.apple.com/videos/wwdc/\(year)/\(sessionId)/.*/downloads/wwdc\(year)-\(sessionId)_hd.mp4"
		regexSD = "https://devstreaming-cdn.apple.com/videos/wwdc/\(year)/\(sessionId)/.*/downloads/wwdc\(year)-\(sessionId)_sd.mp4"
    case "2020":
        // "https://devstreaming-cdn.apple.com/videos/wwdc/2020/10097/2/CB3952FA-6597-441E-BC0A-81A7E0F00B65/wwdc2020_10097_hd.mp4?dl=1"
        regexHD = "https://devstreaming-cdn.apple.com/videos/wwdc/\(year)/\(sessionId).*\(sessionId)_hd.mp4"
        regexSD = "https://devstreaming-cdn.apple.com/videos/wwdc/\(year)/\(sessionId).*\(sessionId)_sd.mp4"
    case "2017", "2018", "2019":
        // https and cdn subdomain
        regexHD = regexHD.replacingOccurrences(of: "http://devstreaming.apple.com", with: "https://devstreaming-cdn.apple.com")
        regexSD = regexSD.replacingOccurrences(of: "http://devstreaming.apple.com", with: "https://devstreaming-cdn.apple.com")
        regexPDF = regexPDF.replacingOccurrences(of: "http://devstreaming.apple.com", with: "https://devstreaming-cdn.apple.com")
    case "2014":
        // .mov istead
        regexHD = regexHD.replacingOccurrences(of: ".*.mp4", with: ".*.mov")
        regexSD = regexSD.replacingOccurrences(of: ".*.mp4", with: ".*.mov")
    default:
        break
    }

    // Setup to for the directory to download the files to
    guard let wwdcDirectoryUrl = ensureWwdcDirectoryIsCreated(in: directory, year: year) else {
        print("Could not create WWDC directory")
        return
    }

    var destinationUrl = wwdcDirectoryUrl.appendingPathComponent("\(sessionId).mp4")
    var destinationUrlString = destinationUrl.absoluteString.replacingOccurrences(of: "file://", with: "")

    let regexTitle = "data-video-name=\"(.*?)\""
    let title = playPageHtml.capturedGroupsWithSingleMatch(regex: regexTitle).first
    if let title = title {
        print("Title: \(title)")
        let normalizedTitle = title.replacingOccurrences(of: "/", with: "+", options: .literal, range: nil)
        destinationUrl = wwdcDirectoryUrl.appendingPathComponent("\(sessionId)-\(normalizedTitle).mp4")
        destinationUrlString = destinationUrl.absoluteString.replacingOccurrences(of: "file://", with: "")
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
                print("Video URL: \(urlVideo!.absoluteString)")
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
            // Download
            print("Downloading from \(urlVideo). Please wait..")

            if !useYoutubeDl {
                var filename: String? = nil
                if let title = title {
                    let normalizedTitle = title.replacingOccurrences(of: "/", with: "+", options: .literal, range: nil)
                    filename = "\(sessionId)-\(normalizedTitle).mp4"
                }
                HttpDownloader.loadFileSync(urlVideo, inDirectory: directory, inYear: year, filename: filename, completion: { path, error in
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    } else {
                        print("Video downloaded to: \(path!)")
                    }
                })
            } else {
                // TODO: destinationUrlString is /path/to/<sessionid>.mp4. It should be a directory to save the file in, and using the url as file name.
                downloadWithYoutubeDl(url: urlVideo.absoluteString, in: destinationUrlString)
            }
        } else {
            // Try HLS
            let matchesHls = matchesForRegexInText(regexHls, text: playPageHtml)
            if matchesHls.count > 0 {
                // This is HLS
                let hlsUrlString = matchesHls[0]
                downloadWithYoutubeDl(url: hlsUrlString, in: destinationUrlString)
            }
        }
    }
}

func findAllSessionIds(inYear year: String = currentYear) -> [String]? {
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
            let matchedRange = result.range(at: 1)
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

// Sensible defaults
var sessionIds = [String]()  // -s 123,456 or if nil, download all!
var isDownloadAll = false // -a to download all
var isVideoResolutionHD = true // -f HD (default), -f SD
var wantsPDFOnly = false // --pdfonly
var wantsPDF = true // --nopdf
var directoryToSaveTo: String? = nil // nil will be user's Documents directory
var year = currentYear // -y 2015
var useYoutubeDl = false

// Processing launch arguments
// http://ericasadun.com/2014/06/12/swift-at-the-command-line/
let arguments = ProcessInfo.processInfo.arguments as [String]
let dashedArguments = arguments.filter { $0.hasPrefix("-") }

for argument : String in dashedArguments {
    let offset = argument.index(argument.startIndex, offsetBy: 1)
    let key = String(argument[offset...])
    let value = UserDefaults.standard.value(forKey: key)
    let valueString = value as? String
    // print("    \(argument) \(value ?? "no value")")

    if argument == "-d" {
        if let directory = valueString {
            directoryToSaveTo = directory
        }
    }
    
    if argument == "-f" && valueString == "SD" {
        isVideoResolutionHD = false
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

    if argument == "--youtubedl" {
        useYoutubeDl = true
    }

}

if isDownloadAll {
    sessionIds = findAllSessionIds(inYear: year)!
}

for sessionId in sessionIds {
    downloadSession(inYear: year, forSession: sessionId, wantsPDF: wantsPDF, wantsPDFOnly: wantsPDFOnly, isVideoResolutionHD: isVideoResolutionHD, inDirectory: directoryToSaveTo, useYoutubeDl: useYoutubeDl)
}

// Test
//findAllSessionIds()
//findAllSessionIds(inYear: "2017")
//downloadSession(inYear: "2014", forSession: "228", wantsPDF: true, wantsPDFOnly: false, isVideoResolutionHD: true, inDirectory: directoryToSaveTo)
//downloadSession(inYear: "2016", forSession: "104", wantsPDF: false, wantsPDFOnly: false, isVideoResolutionHD: false, inDirectory: directoryToSaveTo)
//downloadSession(inYear: "2017", forSession: "701", wantsPDF: true, wantsPDFOnly: false, isVideoResolutionHD: false, inDirectory: directoryToSaveTo) // HLS
//downloadSession(inYear: "2018", forSession: "202", wantsPDF: true, wantsPDFOnly: false, isVideoResolutionHD: true, inDirectory: directoryToSaveTo, useYoutubeDl: true)
//downloadSession(inYear: "2020", forSession: "10228", wantsPDF: true, wantsPDFOnly: false, isVideoResolutionHD: true, inDirectory: directoryToSaveTo, useYoutubeDl: false)

// All 2020
//if let ids = findAllSessionIds(inYear: "2020") {
//    ids.forEach {
//        downloadSession(inYear: "2020", forSession: $0, wantsPDF: true, wantsPDFOnly: false, isVideoResolutionHD: true, inDirectory: directoryToSaveTo, useYoutubeDl: false)
//    }
//}
