# wwdc-dl 

This helps to download WWDC 2016 videos and PDF easily.

Built with Swift scripts!


## Usage
  
  // Main script executable first
  chmod +x wwdc-dl.swift
  
  // Run it
  ./wwdc-dl.swift -s 102,402
  
That will download session 102 and 402. 

By default, the script will download the SD video and PDF in your `~/Documents/WWDC-2016`.


## Advanced Usage

  // HD video
  ./wwdc-dl.swift -s 102 -f HD
  
  // Wants PDF only (no video)
  ./wwdc-dl.swift -s 102 --pdfonly
  
  // For some reason you don't want PDF
  ./wwdc-dl.swift -s 102 --nopdf
  
  
## Playground
  
The script is written in Playground environment for convenience. It makes a copy to `wwdc-dl.swift`.
