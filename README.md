to get sha1 key run this command in terminal
keytool -list -v -keystore ~/.android/debug.keystore

dart run build_runner watch -d

// run every time when git pull
dart run tools/setup.dart

//If debugger give error: Missing application ID. AdMob publishers should follow the instructions
-> Configure your debugger for flavour (https://docs.flutter.dev/deployment/flavors)
OR
-> Run "flutter run --flavor dev" in terminal
            |
            |
            ----> For production
            1. register production admob project application_id in "/android/app/src/prod/AndroidManifest.xml"
            2. Create a interstistial unit and add the unit id in .env