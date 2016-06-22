# wwdc-dl

This helps to download WWDC 2016 videos and PDF easily.

Built with Swift scripts!

_This started as a quick hack at 4am. [Read more](http://samwize.com/2016/06/16/swift-script-to-download-all-wwdc-2016-videos-and-pdfs-automatically/)._


## Usage

    # Main script executable first
    chmod +x wwdc-dl.swift
    
    # Run it
    ./wwdc-dl.swift -s 102,402

That will download session 102 and 402.

By default, the script will download the SD video and PDF in your `~/Documents/WWDC-2016`.


## Advanced Usage

    # HD video
    ./wwdc-dl.swift -s 102 -f HD

    # Wants PDF only (no video)
    ./wwdc-dl.swift -s 102 --pdfonly

    # For some reason you don't want PDF
    ./wwdc-dl.swift -s 102 --nopdf


## Playground

The script is written in Playground environment, for convenience. Edit in Playground, then make a copy to `wwdc-dl.swift` with `copy.sh`.
