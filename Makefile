install:


test:
	set -o pipefail && xcodebuild clean test -scheme RequestKit -sdk iphonesimulator | xcpretty -c
