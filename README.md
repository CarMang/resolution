This version:

1. Focuses specifically on macOS using PF (Packet Filter)
2. Removes the proxy approach in favor of direct packet filtering
3. Creates a simple domain allowlist system
4. Uses proper firewall rules to block/allow traffic

- Removed the cross-platform code since you only need macOS support
- Removed the proxy setup in favor of direct packet filtering
- Added a proper domain allowlist structure
- Fixed the compiler error by removing the `os.isUnix` check

To use this program:

1. Add your allowed domains to the `allowed_domains` list in the `main` function
2. Run it with sudo (required for PF access): `sudo zig run main.zig`

Important notes:
1. The program needs root privileges to modify PF rules
2. It will block all HTTP/HTTPS traffic except to the specified domains
3. The program keeps running to maintain the rules (you can modify this behavior if you want)

To make this work effectively:
1. Make sure PF is enabled on your Mac
2. You might need to temporarily disable any other firewall software
3. The domains must be exact matches

Would you like me to add any specific features or modify the behavior in any way?
