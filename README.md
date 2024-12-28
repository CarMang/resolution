# Resolution
This program allows one to commit a resolution on LLM-only web accessing.

## How It Works

The program uses the `pfctl` (Packet Filter control) utility on Unix-like systems to enforce firewall rules. It blocks all outgoing traffic on ports 80 (HTTP) and 443 (HTTPS) except for the domains explicitly allowed in the configuration.

### Key Features:
- **Domain Whitelisting**: You can specify exact domains (e.g., `www.github.com`) or wildcard domains (e.g., `.github.com` to allow all subdomains).
- **Dynamic Rule Application**: The program dynamically generates and applies the firewall rules based on the allowed domains.
- **Graceful Shutdown**: The program runs continuously until interrupted (e.g., by pressing `CTRL+C`), at which point it shuts down gracefully.

## Usage

1. **Compile the Program**:
   Ensure you have Zig installed, then compile the program using the following command:
   ```bash
   sudo zig build run
   ```

3. **Interrupt the Program**:
   To stop the program, press `CTRL+C`. The program will shut down gracefully, and the firewall rules will remain in place until manually reset.

## Configuration

The list of allowed domains is defined in the `main` function within the `AllowedDomains` struct. You can modify this list to include or exclude specific domains as needed.

```zig
const allowed_domains = AllowedDomains{
    .domains = &[_][]const u8{
        "claude.ai", // Exact match for claude.ai
        ".claude.ai", // Matches all subdomains of claude.ai
        "www.github.com",
        ".github.com", // All subdomains of github.com
        "www.chat.com",
        ".chat.com", // ChatGPT
        "www.deepseek.com", // DeepSeek
        ".deepseek.com",
    },
};
```

## Dependencies

- **Zig**: The program is written in Zig, so you need the Zig compiler to build it.
- **pfctl**: The program relies on the `pfctl` utility, which is typically available on Unix-like systems (e.g., macOS, FreeBSD).

## Notes

- **Root Privileges**: Running this program may require root privileges to modify firewall rules.
- **Persistence**: The firewall rules applied by this program are not persistent across reboots. You would need to run the program again after a system restart.

## License

This program is open-source and available under the MIT License. Feel free to modify and distribute it as needed.

---

This program is a simple yet effective way to control network traffic, especially for users who want to restrict access to specific domains while using LLMs or other services.
