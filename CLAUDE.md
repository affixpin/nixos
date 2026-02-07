# NixOS Configuration

## Architecture
- **Target**: aarch64-linux (ARM64)
- **Runtime**: UTM virtual machine on macOS (Apple Silicon) host
- **Primary goal**: Maximum native performance on macOS + UTM setup
- **Interface**: Headless (SSH only, no GUI/desktop environment)

## Key decisions
- Flakes-based configuration
- Host: `affixos`
