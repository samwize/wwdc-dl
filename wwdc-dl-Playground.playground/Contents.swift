#!/usr/bin/swift

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
        let destinationUrl = documentsUrl
            .URLByAppendingPathComponent("WWDC-2016")
            .URLByAppendingPathComponent(url.lastPathComponent!)
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
    // print("    \(argument) \(value)")
    
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
    let playPageUrl = "https://developer.apple.com/videos/play/wwdc2016/\(sessionId)/"
    let playPageHtml = htmlPage(withURL: playPageUrl)

    // Examples:
    // http://devstreaming.apple.com/videos/wwdc/2016/802z6j79sd7g5drr7k7/802/802_hd_designing_for_tvos.mp4
    // http://devstreaming.apple.com/videos/wwdc/2016/802z6j79sd7g5drr7k7/802/802_sd_designing_for_tvos.mp4
    // http://devstreaming.apple.com/videos/wwdc/2016/802z6j79sd7g5drr7k7/802/802_designing_for_tvos.pdf
    let regexHD = "http://devstreaming.apple.com/videos/wwdc/2016/\(sessionId).*/\(sessionId)/\(sessionId)_hd_.*.mp4"
    let regexSD = "http://devstreaming.apple.com/videos/wwdc/2016/\(sessionId).*/\(sessionId)/\(sessionId)_sd_.*.mp4"
    let regexPDF = "http://devstreaming.apple.com/videos/wwdc/2016/\(sessionId).*/\(sessionId)/\(sessionId)_.*.pdf"

    let matchesHD = matchesForRegexInText(regexHD, text: playPageHtml!)[0]
    let matchesSD = matchesForRegexInText(regexSD, text: playPageHtml!)[0]
    let matchesPDF = matchesForRegexInText(regexPDF, text: playPageHtml!)[0]


    if wantsPDF {
        let urlPDF = NSURL(string: matchesPDF)
        HttpDownloader.loadFileSync(urlPDF!, completion:{(path:String, error:NSError!) in
            print("PDF downloaded to: \(path)")
        })
    }

    if wantsPDFOnly == false {
        let urlVideo = NSURL(string: isVideoResolutionHD ? matchesHD : matchesSD)
        HttpDownloader.loadFileSync(urlVideo!, completion:{(path:String, error:NSError!) in
            print("Video downloaded to: \(path)")
        })
    }
}
