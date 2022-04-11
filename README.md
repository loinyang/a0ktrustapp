You need to enable : OAuth APIs,  People API, Driver Api.

Make sure you've filled out all required fields in the console for OAuth consent screen. Otherwise, you may encounter APIException errors.


Android User

You don't need to include the google-services.json file in your app.


Ios User

replace "yourrealteamID" to your true teamID in the file (ios/pub_appstore.plist ios/pub_ipa.plist),such as 1234567

replase "yourealgoogleapidomian" to your real google api service's domainname  in the file (ios/Runner/Info.plist),such as com.google.api.1234567

replase ios/Runner/GoogleService-Info.plist to your real google api service's download file
