"""
A GitHub Action for sending messages to Zulip, written in Pony.

This package provides the core logic for parsing GitHub Actions input
environment variables, connecting to a Zulip server over HTTPS, and
sending a single message via the Zulip API.

The primary entry point for users is the Docker container action defined
in `action.yml`. For programmatic use, create an `Input` via
`InputParser`, then pass it to `ZulipClient` along with a
`ResultNotify` handler.
"""
