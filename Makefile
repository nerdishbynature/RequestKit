install:
	brew install python
	sudo pip install codecov

test:
	pod lib lint --quick
	set -o pipefail && xcodebuild clean test -scheme RequestKit -sdk iphonesimulator -enableCodeCoverage YES ONLY_ACTIVE_ARCHS=YES | xcpretty -c

post_coverage:
	bundle exec slather coverage --input-format profdata -x --ignore "../**/*/Xcode*" --ignore "Carthage/**" --output-directory slather-report --scheme RequestKit RequestKit.xcodeproj
	codecov -f slather-report/cobertura.xml

