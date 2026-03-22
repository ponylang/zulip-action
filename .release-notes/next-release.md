## Fix connection hang on exit

The action could hang indefinitely instead of exiting cleanly when the Zulip server's close notification was missed in a narrow timing window. The connection would get stuck waiting for a response that would never come, causing the GitHub Actions step to run until the workflow timeout.

## Fix TLS certificate verification accepting empty certificate names

TLS certificate hostname verification could incorrectly report that a certificate was valid for any hostname when the certificate's name list contained an empty string. An empty name now correctly fails to match.

## Fix connection resource leak on early close

Closing a connection while it was still being established could leak internal connection resources.
