to get sha1 key run this command in terminal
keytool -list -v -keystore ~/.android/debug.keystore

dart run build_runner watch -d

// run every time when git pull
dart run tools/setup.dart

//If debugger give error: Missing application ID. AdMob publishers should follow the instructions
-> Configure your debugger for flavour (https://docs.flutter.dev/deployment/flavors)
OR
-> Run "flutter run --flavor dev" in terminal

----> For production
            1. register production admob project application_id in "/android/app/src/prod/AndroidManifest.xml"
            2. Create a interstistial unit and add the unit id in .env


//Analytics setup documentaion

1. Install firebase cli -> "npm install -g firebase-tools"

2. Login to firebase console -> "firebase login"

3. Install the FlutterFire CLI by running the following command from any directory -> "dart pub global activate flutterfire_cli"

3.5 For linux, not sure about windows: After running look into the logs and add path for global access, i will look something like 
                                        this "export PATH="$PATH":"$HOME/.   pub-cache/bin""

4. From your Flutter project directory -> "flutterfire configure"

// Test Analytics (firebase debug mode)

1. To enable Analytics debug mode on an Android device, execute the following commands: 
    -> adb shell setprop debug.firebase.analytics.app  com.example.codeyogienglishcourse

    This behavior persists until you explicitly disable debug mode by executing the following command:
    -> adb shell setprop debug.firebase.analytics.app .none.

