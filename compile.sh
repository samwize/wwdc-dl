#!/bin/bash
echo -e "#!/usr/bin/swift\n$(cat wwdc-dl-Playground.playground/Contents.swift)" > wwdc-dl-tmp.swift
xcrun -sdk macosx swiftc wwdc-dl-tmp.swift -o wwdc-dl