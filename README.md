# FlirtBook

A Flutter application for generating flirty messages.

## Running the Web Version

To run the web version of this app, you need to start a local proxy server to handle CORS issues:

1. Install Node.js dependencies:
   ```
   npm install
   ```

2. Start the proxy server:
   ```
   npm start
   ```

3. In a separate terminal, run the Flutter web app:
   ```
   flutter run -d chrome
   ```

4. Access the app at http://localhost:8080

## CORS Issues

If you're experiencing CORS issues when running the web version, make sure:

1. The proxy server is running
2. You're accessing the app through the server URL (http://localhost:3000)

## Alternative Solution

If you don't want to run a local server, you can use a browser extension to disable CORS:

1. For Chrome, install the "CORS Unblock" extension
2. Enable the extension when using the app

## Mobile Version

The mobile version doesn't have CORS issues and can be run normally:

```
flutter run
```

## Original Flutter Documentation

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Online documentation](https://docs.flutter.dev/)
