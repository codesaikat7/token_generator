# Bluetooth Printing for Thermal Printers (SPP/Classic Bluetooth)

This app now supports Bluetooth printing for thermal printers using `blue_thermal_printer` package, specifically designed for **Classic Bluetooth (SPP)** thermal printers. This provides much better compatibility and reliability for traditional thermal printer hardware.

## Features

- **SPP Bluetooth Support**: Optimized for Classic Bluetooth (SPP) thermal printers
- **Bonded Device Discovery**: Automatically finds already paired Bluetooth devices
- **Smart Device Filtering**: Filters for common thermal printer brands and models
- **Easy Connection**: One-tap connection to your SPP printer
- **Automatic Printing**: Prints tokens in the correct ESC/POS format for thermal printers
- **Support for Multiple Tokens**: Print individual tokens or all tokens at once
- **Comprehensive Debug Logging**: Detailed logging for troubleshooting

## Supported Printer Types

The app automatically detects and filters for these common SPP thermal printer types:
- Generic thermal printers with SPP Bluetooth
- POS (Point of Sale) printers
- Receipt printers
- ESC/POS compatible printers
- Star, Citizen, Epson, Brother thermal printers
- HC-05, HC-06 Bluetooth modules
- JDY Bluetooth modules
- Classic Bluetooth thermal printers

## How to Use

### 1. Prepare Your Printer
- Turn on your thermal printer
- Enable Bluetooth on the printer
- **Pair your printer with your device first** (this is required for SPP)
- Make sure the printer is within Bluetooth range (usually 10 meters)

### 2. Select a Printer
- Go to any print screen (Print Preview or Print All Tokens)
- Tap the "Select Printer" button (Bluetooth icon)
- The app will automatically scan for **bonded (paired)** devices
- Select your printer from the list
- Tap "Connect" to establish the SPP connection

### 3. Print Tokens
- Once connected, the button will change to "Print Now"
- Tap to print your tokens
- The app will send the print data in the correct ESC/POS format for thermal printers

## Printer Requirements

Your thermal printer must support:
- **Classic Bluetooth (SPP) connectivity** (not BLE)
- ESC/POS command set (most thermal printers do)
- 80mm paper width (configurable in the code if needed)
- **Must be paired with your device before use**

## SPP vs BLE (Bluetooth Low Energy)

| Feature | SPP (Classic Bluetooth) | BLE (Bluetooth Low Energy) |
|---------|-------------------------|----------------------------|
| **Compatibility** | ✅ Most thermal printers | ❌ Limited thermal printer support |
| **Reliability** | ✅ Very reliable | ⚠️ Can be unstable |
| **Speed** | ✅ Fast data transfer | ⚠️ Slower data transfer |
| **Range** | ✅ Better range | ❌ Limited range |
| **Setup** | ⚠️ Requires pairing first | ✅ Automatic discovery |
| **Battery** | ❌ Higher power usage | ✅ Lower power usage |

## Troubleshooting

### No Printers Found
- **Ensure your printer is paired with your device first**
- Check that Bluetooth is enabled on your device
- Verify the printer supports Classic Bluetooth (SPP)
- Restart the printer and try again

### Connection Failed
- Make sure the printer is not connected to another device
- Check that the printer supports SPP Bluetooth
- Try disconnecting and reconnecting
- Verify the printer is in pairing mode if needed

### Print Quality Issues
- Check that the printer has enough paper
- Ensure the printer is not in low-power mode
- Verify the printer supports the ESC/POS commands being sent
- Check SPP connection stability

## Technical Details

The app uses:
- **blue_thermal_printer**: For SPP Bluetooth device discovery and communication
- **esc_pos_utils**: For generating ESC/POS print commands
- **Custom Bluetooth Service**: For managing SPP printer connections and data transmission

## Permissions Required

### Android
- `BLUETOOTH`
- `BLUETOOTH_ADMIN`
- `BLUETOOTH_CONNECT`
- `ACCESS_FINE_LOCATION` (for Classic Bluetooth)

### iOS
- `NSBluetoothAlwaysUsageDescription`
- `NSBluetoothPeripheralUsageDescription`

## Code Structure

- `BluetoothPrintService`: Manages SPP Bluetooth connections and printing
- `BluetoothPrinterDialog`: UI for selecting and connecting to SPP printers
- `PrintService`: Integrates SPP Bluetooth printing with existing functionality
- Updated print screens to support SPP Bluetooth printing

## Debug Logging

The app provides comprehensive debug logging for SPP operations:

```
🔍 Starting Bluetooth SPP device scan...
📱 Scan results: Found X bonded devices
🔍 Device: [Printer Name] ([Address]) - Likely printer: true
=== STARTING SPP DEVICE CONNECTION ===
🔌 Attempting to connect to: [Printer Name] ([Address])
⏳ Connecting to SPP device...
✅ Successfully connected to SPP device
=== STARTING RECEIPT PRINT ===
📊 Generated X bytes of ESC/POS data
🚀 Starting print transmission...
=== STARTING SPP DATA PRINT ===
📦 Will send data in X chunks of 512 bytes each
📤 Sending chunk 1/X (512 bytes)...
✍️ Writing chunk via SPP...
✅ Chunk 1 written successfully via SPP
📈 Progress: 1/X chunks sent (X.X%)
🎉 SPP print operation completed successfully!
```

## Future Enhancements

- Save printer preferences for faster reconnection
- Support for different paper sizes
- Print preview before sending to printer
- Batch printing with custom formatting options
- Printer status monitoring (paper level, connectivity, etc.)
- Enhanced SPP connection stability

## Why SPP is Better for Thermal Printers

1. **Industry Standard**: Most thermal printers use SPP Bluetooth
2. **Reliable Data Transfer**: SPP provides guaranteed data delivery
3. **Faster Printing**: Larger chunk sizes (512 bytes vs 100 bytes)
4. **Better Compatibility**: Works with older and newer thermal printers
5. **Stable Connections**: SPP connections are more reliable than BLE
6. **Wider Support**: Supported by virtually all thermal printer manufacturers

This implementation provides the best possible compatibility and reliability for thermal printer Bluetooth printing!
