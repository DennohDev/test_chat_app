# Firebase Chat App with Messaging using Cloud Functions

This guide walks you through setting up a simple chat app with Firebase email authentication and messaging support using Firebase Cloud Functions. This app allows authenticated users to send messages to each other.

---

## 1. **Prerequisites**

- Ensure Flutter project is initialized.
- Firebase is connected to your project.
- Firebase CLI is installed.
- A Firebase project is created and linked.

---

## 2. **Enable Firebase Authentication**

- Go to Firebase Console.
- Select your project.
- Navigate to Authentication > Sign-in Method.
- Enable the Email/Password sign-in provider.

---

## 3. **Set up Firebase Cloud Firestore**

- Open Firestore Database in the Firebase Console.
- Create a new Firestore database.
- Choose test mode for development.
- Select your preferred region and enable.

---

## 4. **Design Firestore Data Structure**

- Create a `users` collection to store user details (e.g., email, fcmToken).
- Create a `messages` collection to store chat messages.

---

## 5. **Prepare Flutter Dependencies**

- Add the required Firebase and Firestore packages in `pubspec.yaml`.
- Initialize Firebase in your app's entry point.

---

## 6. **Authentication Flow**

- Build sign-up and login functionality.
- On successful signup, add user data to Firestore under the `users` collection.

---

## 7. **User Messaging Flow**

- When a user sends a message, store the message in the `messages` collection.
- Ensure each message includes sender ID, receiver ID, content, and timestamp.

---

## 8. **Set up Firebase Messaging (FCM)**

- Enable Cloud Messaging in the Firebase Console.
- Retrieve the device token from FCM.
- Store the token in the user's document in Firestore.

---

## 9. **Set up Firebase Cloud Functions**

- Initialize Cloud Functions in your project directory.
- Write a function to trigger on new message creation.
- Fetch the recipient's FCM token.
- Send a notification using the token.
- Deploy the function.

---

## 10. **Configure Message Reception in App**

- Listen for foreground messages in your Flutter app.
- Handle notifications in background and terminated states.

---

## 11. **Flutter Page Flow**

### Splash Page
- Check for authentication state.
- Redirect to either Login or Home Page.

### Login Page
- Email and password input fields.
- Button to log in.
- Navigation link to Signup Page.

### Signup Page
- Input fields for email, password, and confirm password.
- Button to create account.
- After signup, redirect to Home Page.

### Home Page
- Display a list of other users from the `users` collection.
- Tapping a user opens a chat session.

### Chat Page
- Display chat messages exchanged with the selected user.
- Show input field to type a new message.
- Include a send button.

---

## ✅ Summary

You now have:
- Email authentication using Firebase.
- User profiles stored in Firestore.
- Messaging system using Firestore.
- Push notifications via Cloud Functions and FCM.
- Basic page structure for login, signup, home, and chat functionality.

You can continue building features like message status indicators, user presence, typing indicators, and media messages.

