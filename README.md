# wwdc-dl

This helps to download WWDC 2016 videos and PDF easily. 

Built with Swift 3 scripts!

_This started as a quick hack at 4am. [Read more](http://samwize.com/2016/06/16/swift-script-to-download-all-wwdc-2016-videos-and-pdfs-automatically/)._

Wait.. WWDC 2015 and 2014 are supported too!


## Usage

    # Download all PDFs
    ./wwdc-dl -a --pdfonly
    
    # Download for specific session
    ./wwdc-dl -s 102,402

By default, the script will download the SD video and PDF in your `~/Documents/WWDC-2016`.


## Advanced Usage

    # HD video
    ./wwdc-dl -s 102 -f HD

    # Wants PDF only (no video)
    ./wwdc-dl -s 102 --pdfonly

    # Download all
    ./wwdc-dl -a --pdfonly

    # For some reason you don't want PDF
    ./wwdc-dl -s 102 --nopdf

    # For other years
    ./wwdc-dl -s 102 -y 2014
    
    # Specific the directory to save in
    ./wwdc-dl -s 102 -d /Volumes/AwesomeDrive/


## Playground

This script is written in Playground environment, for convenience. 

If you are developing, edit in Playground, then run `./compile.sh`.
