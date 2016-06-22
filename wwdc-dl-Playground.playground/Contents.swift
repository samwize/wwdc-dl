
import Foundation

// http://stackoverflow.com/a/26135752/242682
func htmlPage(withURL url: String) -> String? {
    guard let myURL = NSURL(string: url) else {
        print("Error: \(url) doesn't seem to be a valid URL")
        return nil
    }
    
    do {
        let myHTMLString = try String(contentsOfURL: myURL)
        return myHTMLString
    } catch let error as NSError {
        print("Error: \(error)")
    }
    return nil
}

// http://stackoverflow.com/a/27880748/242682
func matchesForRegexInText(regex: String!, text: String!) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex, options: [])
        let nsString = text as NSString
        let results = regex.matchesInString(text,
                                            options: [], range: NSMakeRange(0, nsString.length))
        return results.map { nsString.substringWithRange($0.range)}
    } catch let error as NSError {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}

// http://stackoverflow.com/a/30106868/242682
class HttpDownloader {
    class func loadFileSync(url: NSURL, completion:(path:String, error:NSError!) -> Void) {
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
        let wwdcDirectoryUrl = documentsUrl.URLByAppendingPathComponent("WWDC-2016")
        createWWDCDirectory(wwdcDirectoryUrl)

        let destinationUrl = wwdcDirectoryUrl.URLByAppendingPathComponent(url.lastPathComponent!)
        if NSFileManager().fileExistsAtPath(destinationUrl.path!) {
            print("file already exists [\(destinationUrl.path!)]")
            completion(path: destinationUrl.path!, error:nil)
        } else if let dataFromURL = NSData(contentsOfURL: url){
            
            if dataFromURL.writeToURL(destinationUrl, atomically: true) {
                // print("file saved [\(destinationUrl.path!)]")
                completion(path: destinationUrl.path!, error:nil)
            } else {
                print("error saving file")
                let error = NSError(domain:"Error saving file", code:1001, userInfo:nil)
                completion(path: destinationUrl.path!, error:error)
            }
        } else {
            let error = NSError(domain:"Error downloading file", code:1002, userInfo:nil)
            completion(path: destinationUrl.path!, error:error)
        }
        
    }

    class func createWWDCDirectory(directory: NSURL) {
        if NSFileManager.defaultManager().fileExistsAtPath(directory.path!) == false {
            do {
                try NSFileManager.defaultManager().createDirectoryAtURL(directory, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print("Error creating WWDC-2016 directory in Documents: \(error.localizedDescription)")
            }
        }
    }
}

func downloadSession(sessionId: String, wantsPDF: Bool, wantsPDFOnly: Bool, isVideoResolutionHD: Bool) {
    let playPageUrl = "https://developer.apple.com/videos/play/wwdc2016/\(sessionId)/"
    let playPageHtml = htmlPage(withURL: playPageUrl)
    
    // Examples:
    // http://devstreaming.apple.com/videos/wwdc/2016/802z6j79sd7g5drr7k7/802/802_hd_designing_for_tvos.mp4
    // http://devstreaming.apple.com/videos/wwdc/2016/802z6j79sd7g5drr7k7/802/802_sd_designing_for_tvos.mp4
    // http://devstreaming.apple.com/videos/wwdc/2016/802z6j79sd7g5drr7k7/802/802_designing_for_tvos.pdf
    let regexHD = "http://devstreaming.apple.com/videos/wwdc/2016/\(sessionId).*/\(sessionId)/\(sessionId)_hd_.*.mp4"
    let regexSD = "http://devstreaming.apple.com/videos/wwdc/2016/\(sessionId).*/\(sessionId)/\(sessionId)_sd_.*.mp4"
    let regexPDF = "http://devstreaming.apple.com/videos/wwdc/2016/\(sessionId).*/\(sessionId)/\(sessionId)_.*.pdf"
    
    if wantsPDF {
        let matchesPDF = matchesForRegexInText(regexPDF, text: playPageHtml!)
        
        if matchesPDF.count > 0 {
            let urlPDF = NSURL(string: matchesPDF[0])
            if let urlPDF = urlPDF {
                HttpDownloader.loadFileSync(urlPDF, completion:{(path:String, error:NSError!) in
                    print("PDF downloaded to: \(path)")
                })
            }
        } else {
            print("Cannot find PDF")
        }
    }
    
    if wantsPDFOnly == false {
        var urlVideo: NSURL?
        if isVideoResolutionHD {
            let matchesHD = matchesForRegexInText(regexHD, text: playPageHtml!)
            if matchesHD.count > 0 {
                urlVideo = NSURL(string: matchesHD[0])
            } else {
                print("Cannot find HD Video")
            }
        } else {
            let matchesSD = matchesForRegexInText(regexSD, text: playPageHtml!)
            if matchesSD.count > 0 {
                urlVideo = NSURL(string: matchesSD[0])
            } else {
                print("Cannot find SD Video")
            }
        }

        if let urlVideo = urlVideo {
            HttpDownloader.loadFileSync(urlVideo, completion:{(path:String, error:NSError!) in
                print("Video downloaded to: \(path)")
            })
        }
    }
}




// Sensible defaults
var sessionIds: [String] = [] // -s 123,456
var isVideoResolutionHD = false // -f HD
var wantsPDFOnly = false // --pdfonly
var wantsPDF = true // --nopdf


// Processing launch arguments
// http://ericasadun.com/2014/06/12/swift-at-the-command-line/
let arguments = NSProcessInfo.processInfo().arguments as [String]
let dashedArguments = arguments.filter({$0.hasPrefix("-")})

for argument : NSString in dashedArguments {
    let key = argument.substringFromIndex(1)
    let value : AnyObject? = NSUserDefaults.standardUserDefaults().valueForKey(key)
    let valueString = value as? String
    // print("    \(key) \(value)")
    
    if key == "f" && valueString == "HD" {
        isVideoResolutionHD = true
    }
    
    if key == "-nopdf" {
        wantsPDF = false
    }
    
    if key == "-pdfonly" {
        wantsPDFOnly = true
    }
    
    if key == "s" {
        sessionIds = (valueString?.componentsSeparatedByString(","))!
        print("Downloading for sessions: \(sessionIds)")
    }
}

// Download them all!
for sessionId in sessionIds {
    downloadSession(sessionId, wantsPDF: wantsPDF, wantsPDFOnly: wantsPDFOnly, isVideoResolutionHD: isVideoResolutionHD)
}

// Test
// downloadSession("104", wantsPDF: false, wantsPDFOnly: false, isVideoResolutionHD: false)

