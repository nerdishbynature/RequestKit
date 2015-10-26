install:


test:
	set -o pipefail && xcodebuild clean test -scheme RequestKit -sdk iphonesimulator9.0 | xcpretty -c -r junit --output $(CIRCLE_TEST_REPORTS)/xcode/results.xml
