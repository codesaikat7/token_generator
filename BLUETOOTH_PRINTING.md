# Bluetooth Printing for Thermal Printers

This app now supports Bluetooth printing for thermal printers, allowing you to print tokens directly from your mobile device.

## Features

- **Bluetooth Device Discovery**: Automatically scans for nearby Bluetooth thermal printers
- **Smart Device Filtering**: Filters for common thermal printer brands and models
- **Easy Connection**: One-tap connection to your printer
- **Automatic Printing**: Prints tokens in the correct ESC/POS format for thermal printers
- **Support for Multiple Tokens**: Print individual tokens or all tokens at once

## Supported Printer Types

The app automatically detects and filters for these common thermal printer types:
- Generic thermal printers
- POS (Point of Sale) printers
- Receipt printers
- ESC/POS compatible printers
- Star, Citizen, Epson, Brother thermal printers

## How to Use

### 1. Prepare Your Printer
- Turn on your thermal printer
- Enable Bluetooth on the printer
- Put the printer in pairing/discovery mode
- Make sure the printer is within Bluetooth range (usually 10 meters)

### 2. Select a Printer
- Go to any print screen (Print Preview or Print All Tokens)
- Tap the "Select Printer" button (Bluetooth icon)
- The app will automatically scan for nearby printers
- Select your printer from the list
- Tap "Connect" to establish the connection

### 3. Print Tokens
- Once connected, the button will change to "Print Now"
- Tap to print your tokens
- The app will send the print data in the correct format for thermal printers

## Printer Requirements

Your thermal printer must support:
- Bluetooth connectivity
- ESC/POS command set (most thermal printers do)
- 80mm paper width (configurable in the code if needed)

## Troubleshooting

### No Printers Found
- Ensure Bluetooth is enabled on your device
- Check that the printer is in pairing mode
- Move closer to the printer
- Restart the printer and try again

### Connection Failed
- Make sure the printer is not connected to another device
- Check that the printer supports the required Bluetooth profiles
- Try disconnecting and reconnecting

### Print Quality Issues
- Check that the printer has enough paper
- Ensure the printer is not in low-power mode
- Verify the printer supports the ESC/POS commands being sent

## Technical Details

The app uses:
- **flutter_blue_plus**: For Bluetooth device discovery and communication
- **esc_pos_utils**: For generating ESC/POS print commands
- **Custom Bluetooth Service**: For managing printer connections and data transmission

## Permissions Required

### Android
- `BLUETOOTH`
- `BLUETOOTH_ADMIN`
- `BLUETOOTH_SCAN`
- `BLUETOOTH_CONNECT`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`

### iOS
- `NSBluetoothAlwaysUsageDescription`
- `NSBluetoothPeripheralUsageDescription`
- `NSLocationWhenInUseUsageDescription`

## Code Structure

- `BluetoothPrintService`: Manages Bluetooth connections and printing
- `BluetoothPrinterDialog`: UI for selecting and connecting to printers
- `PrintService`: Integrates Bluetooth printing with existing print functionality
- Updated print screens to support Bluetooth printing

## Future Enhancements

- Save printer preferences for faster reconnection
- Support for different paper sizes
- Print preview before sending to printer
- Batch printing with custom formatting options
- Printer status monitoring (paper level, connectivity, etc.)
