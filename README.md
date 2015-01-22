# Wire

> Connect to Home from anywhere

Wire aims to connect you to home wherever you are. The idea is:

    POST /wire/messages
        body: "Hey a package has been delivered."
        to: 'jesse'
        urgency: [0-1] or
        private: [0-1]
        sensitive: (yes/no)
        visibility:
            'receiver only'
            'receiver and any people around'
            'receiver and their friends'
            'the world'

        # Ths determines whether it can be posted to the internet
        permanent: (yes/no)

        media: [
            {type: 'audio', href: '//somewhere.com'}
            {type: 'image', href: '//somewhere.com'}
            {type: 'video', href: '//somewhere.com'}
        ]


Via a fallback stack all configured channels will be tried to deliver the message.
Some channels are not allowed below certain urgency or privacy levels, or take precedence.

- Home
    + speaker
    + screen
- Browser
    + voice
    + clatter
    + flicker
- App
    + Push notification
- Social
    + twitter
    + facebook
        * private
        * wall
    + google+
        * hangout
        * wall
    + instagram
        * direct
- Phone
    + twilio
    + call

To get the message to specific users, use their location, socket connection in browser and social accounts.
The receiver should also be able to set constraints on the messages received (like thresholds)

Reliability... for now use multiple channels for more reliability. Maybe later add confirmations.