install:


test:
	pod lib lint --quick
	set -o pipefail && xcodebuild clean test -scheme RequestKit -sdk iphonesimulator | xcpretty -c
