#!/bin/bash
rm -f wwdc-dl-tmp.swift
echo "#!/usr/bin/swift" > wwdc-dl-tmp.swift
cat wwdc-dl-Playground.playground/Contents.swift >> wwdc-dl-tmp.swift
xcrun -sdk macosx swiftc wwdc-dl-tmp.swift -o wwdc-dl