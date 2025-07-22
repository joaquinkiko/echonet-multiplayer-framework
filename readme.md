# Snapnet Multiplayer Framework

Reimplementation of Godot multiplayer with snapshot interpolation for fast and action based multiplayer.

This plugin is designed for **[Godot 4.4+](https://godotengine.org/download)**

## Summary of Goals

- Custom implementation of netcode for more modularity
- Focus on snapshot interpolation and server authoratative gameplay
- Player nicknames, ids, and version authentication
- Simple server setup with passwords, chat, lobby management
- Modular support for alternative connection types (i.e. Steam)
- (WIP) Built-in Host Migration on server failure
