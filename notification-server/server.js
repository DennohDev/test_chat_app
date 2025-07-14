const express = require('express');
const admin = require('firebase-admin');
const bodyParser = require('body-parser');
const path = require('path');

const app = express();
app.use(bodyParser.json());

// Initialize Firebase Admin SDK
const serviceAccount = require(path.join(__dirname, 'serviceAccountKey.json'));
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

app.post('/send-notification', async (req, res) => {
  const { fcmToken, title, body, data } = req.body;
  if (!fcmToken || !title || !body) {
    return res.status(400).send('Missing fields');
  }
  try {
    await admin.messaging().sendToDevice(fcmToken, {
      notification: { title, body },
      data: data || {}
    });
    res.send('Notification sent');
  } catch (e) {
    res.status(500).send(e.message);
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
