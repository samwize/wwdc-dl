# wwdc-dl 

This helps to download WWDC 2016 videos and PDF easily.

Built with Swift scripts!


## Usage

Note: The script is in Playground for convenience.
  
  // So get it there
  cd wwdc-dl-Playground.playground
  chmod +x Contents.swift
  
  // Run it
  ./Contents.swift -s 102,402
  
That will download session 102 and 402. 

By default, the script will download the SD video and PDF in your `~/Documents/WWDC-2016`.


## Advanced Usage

  // HD video
  ./Contents.swift -s 102 -f HD
  
  // Wants PDF only (no video)
  ./Contents.swift -s 102 --pdfonly
  
  // For some reason you don't want PDF
  ./Contents.swift -s 102 --nopdf
  