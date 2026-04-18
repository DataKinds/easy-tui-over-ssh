# ROADMAP

* Support for account deletion, through a separate Unix user and confirmation flow.
* Support for account staleness calculations, tracking user registration dates and culling inactive users over a certain account age.
    * This'll probably also imply adding a DB to the Compose file and interacting with that, or pulling in Sqlite during the tunnel container setup.
* Bandwidth testing, along with exposing a number of OpenSSH options to help manage connected clients (`KeepAlive`, etc).
* Simplifying the user registration flow
    * Prompting the user whether they want to directly launch the app after first time registration.
    * More research is required to figure out whether it's possible to stop prompting a user directly for their public key.
* Proper Docker volume setup to persist the authorized users between container launches. 
* Rate limiting on account creation.
* Root access for a single preconfigured keypair.
