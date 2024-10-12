const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000;

let subscribers = [];
const API_KEY = 'wafflechat';
let disposableEmailDomains = [];

fs.readFile(path.join(__dirname, 'blocklist.txt'), 'utf8', (err, data) => {
    if (err) {
        console.error('Error reading blocklist:', err);
        return;
    }
    disposableEmailDomains = data.split('\n').map(domain => domain.trim()).filter(Boolean);
    console.log('Blocklist loaded:', disposableEmailDomains.length, 'domains');
});

app.use(bodyParser.json());
app.use(cors());

function addSubscriber(email) {
    fs.appendFile(path.join(__dirname, 'subscribers.txt'), email + '\n', (err) => {
        if (err) {
            console.error('Error adding subscriber:', err);
        } else {
            console.log('Subscriber added:', email);
        }
    });
}

app.post('/subscribe', (req, res) => {
    const apiKey = req.headers['x-api-key'];
    if (apiKey !== API_KEY) {
        console.warn('Forbidden: Invalid API Key');
        return res.status(403).json({ message: 'Forbidden: Invalid API Key' });
    }

    const { email } = req.body;
    if (!validateEmail(email)) {
        console.warn('Invalid email address');
        return res.status(400).json({ message: 'Invalid email address' });
    }

    if (isDisposableEmail(email)) {
        console.warn('Disposable email addresses are not allowed');
        return res.status(400).json({ message: 'Disposable email addresses are not allowed' });
    }

    if (subscribers.includes(email)) {
        console.warn('Email is already subscribed');
        return res.status(400).json({ message: 'Email is already subscribed' });
    }

    subscribers.push(email);
    addSubscriber(email);
    res.status(200).json({ message: 'Subscribed successfully' });
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});


function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(String(email).toLowerCase());
}

function isDisposableEmail(email) {
    const domain = email.split('@')[1];
    return disposableEmailDomains.includes(domain);
}