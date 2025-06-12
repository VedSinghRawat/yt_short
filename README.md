to get sha1 key run this command in terminal
linux: keytool -list -v -keystore ~/.android/debug.keystore -storepass android
windows: keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android

dart run build_runner watch -d

// run every time when git pull
dart run tools/setup.dart
