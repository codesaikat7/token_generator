# SPP Bluetooth Printing Debug Logging Guide

This document shows all the debug information that will be displayed in the console when using **SPP (Classic Bluetooth)** printing features. This comprehensive logging will help you troubleshoot any printing issues and understand exactly what's happening during the SPP printing process.

## 🔍 **Scanning for SPP Bluetooth Devices**

When scanning for SPP Bluetooth devices, you'll see:

```
🔍 Starting Bluetooth SPP device scan...
📱 Scan results: Found X bonded devices
🔍 Device: [Device Name] ([Address]) - Likely printer: true/false
🛑 Stopping Bluetooth device scan...
✅ Scan stopped
```

**Note**: SPP devices must be paired (bonded) with your device before they appear in the scan results.

## 🔌 **Connecting to an SPP Printer**

When connecting to an SPP Bluetooth printer:

```
=== STARTING SPP DEVICE CONNECTION ===
🔌 Attempting to connect to: [Printer Name] ([Address])
📱 Device type: [Printer Name]
🔑 Device address: [Address]
⏳ Connecting to SPP device...
✅ Successfully connected to SPP device
=== SPP DEVICE CONNECTION COMPLETED ===
```

## 🖨️ **Printing a Receipt**

When printing a receipt, you'll see detailed information about the ESC/POS data generation:

```
=== STARTING RECEIPT PRINT ===
Printer: [Printer Name] ([Address])
Title: [Clinic Title]
Patient: [Patient Name]
Doctor: [Doctor Name]
Token: [Token Number]
DateTime: [Date and Time]
Additional Info: [Additional Info or None]
✅ Printer is ready, generating ESC/POS data...
📋 Loaded printer capability profile: [Profile Name]
🖨️ Created generator for 80mm paper
📝 Generating header...
🔢 Generating token number section...
👤 Generating patient details...
👨‍⚕️ Generating doctor details...
📅 Generating date/time section...
ℹ️ Generating additional info section... (if applicable)
🏁 Generating footer...
✂️ Adding paper cut command...
📊 Generated X bytes of ESC/POS data
🔍 First 50 bytes: 0x1b 0x40 0x1b 0x52 0x0f ...
🚀 Starting print transmission...
```

## 📤 **SPP Data Transmission**

During the actual data transmission to the SPP printer:

```
=== STARTING SPP DATA PRINT ===
📱 Data size: X bytes
🖨️ Target printer: [Printer Name] ([Address])
✅ Printer is ready for data transmission
📊 Converting data: X bytes ready for transmission
📦 Will send data in X chunks of 512 bytes each
📤 Sending chunk 1/X (512 bytes)...
🔍 Chunk 1 data (first 20 bytes): 0x1b 0x40 0x1b 0x52 0x0f ...
✍️ Writing chunk via SPP...
✅ Chunk 1 written successfully via SPP
📈 Progress: 1/X chunks sent (X.X%)
⏳ Waiting 20ms before next chunk...
📤 Sending chunk 2/X (512 bytes)...
...
⏳ Waiting 500ms for SPP printer to process all data...
🎉 SPP print operation completed successfully!
📊 Final stats: Sent X/X chunks (100% success rate)
=== SPP DATA PRINT COMPLETED ===
```

## 📊 **Print Service Integration**

When the print service calls SPP Bluetooth printing:

```
=== STARTING BLUETOOTH TOKEN PRINT ===
🔢 Token: [Token Number]
👤 Patient: [Patient Name]
👨‍⚕️ Doctor: [Doctor Name]
📅 Generated: [Timestamp]
📊 Generated print data: X bytes
🚀 Sending data to Bluetooth printer...
📊 Bluetooth print result: true/false
✅ Bluetooth token print completed successfully! (or failed)
=== BLUETOOTH TOKEN PRINT COMPLETED ===
```

## 🔍 **SPP Device Analysis**

When analyzing if an SPP device is a thermal printer:

```
🔍 Checking if SPP device is likely thermal printer: "[Device Name]"
🔍 Normalized SPP device name: "[lowercase name]"
✅ SPP device matches printer keyword: "thermal" (or other keywords)
✅ SPP device matches printer pattern: [pattern]
❌ SPP device does not appear to be a thermal printer
```

## 🔌 **SPP Connection Status Checks**

When checking SPP connection status:

```
🔍 Checking for valid SPP connection...
   - Connected device: [Device Name or None]
   - Device address: [Address or None]
✅ Valid SPP connection: true/false
🔍 Checking Bluetooth availability...
📱 Bluetooth enabled: true/false
```

## 🧹 **SPP State Management**

When managing SPP service state:

```
=== RESETTING SPP CONNECTION STATE ===
🔄 Before reset:
   - Connected device: [Device Name or None]
   - Device address: [Address or None]
   - Is connecting: true/false
   - Is printing: true/false
✅ After reset:
   - Connected device: None
   - Device address: None
   - Is connecting: false
   - Is printing: false
=== SPP CONNECTION STATE RESET COMPLETED ===
```

## 📱 **SPP Device Information**

When getting SPP device information:

```
📱 Getting display name for SPP device: [Device Name]
🔍 Checking if SPP device is likely thermal printer: [Device Name]
```

## 🚨 **SPP Error Handling**

When errors occur:

```
❌ Print failed: Printer not ready
❌ Print failed: No device connected
❌ Printer became unavailable during printing at chunk X
💥 Failed to write chunk X: [Error Message]
💥 Print failed with error: [Error Message]
❌ Bluetooth print failed: No printer connected
❌ Bluetooth print failed: Invalid connection state
❌ Bluetooth print failed: Printer not ready
💥 Bluetooth printing failed with error: [Error Message]
```

## 🔧 **How to Use This Debug Information**

1. **Run the app in debug mode** to see all console output
2. **Look for the emoji indicators** to quickly identify different types of operations
3. **Check for error messages** (❌ and 💥) to identify issues
4. **Monitor progress indicators** (📈) to see printing progress
5. **Use the section markers** (===) to identify start/end of operations
6. **Look for SPP-specific indicators** to confirm Classic Bluetooth usage

## 📋 **Common SPP Debug Scenarios**

### **Successful SPP Print:**
- Look for ✅ symbols indicating success
- Check that all chunks were sent successfully
- Verify the final success rate is 100%
- Confirm SPP connection status

### **SPP Connection Issues:**
- Look for ❌ symbols in connection sections
- Check if the device is paired (bonded) with your device
- Verify the printer supports Classic Bluetooth (SPP)
- Check Bluetooth permissions are granted

### **SPP Printing Issues:**
- Check if data is being generated correctly
- Monitor chunk transmission progress (512-byte chunks)
- Look for any failed chunk transmissions
- Verify SPP connection stability

### **SPP Device Detection Issues:**
- Check if bonded devices are being found
- Verify printer detection logic is working
- Ensure the printer is paired with your device
- Check for SPP-specific device patterns

## 🆚 **SPP vs BLE Debug Differences**

| Aspect | SPP (Classic Bluetooth) | BLE (Bluetooth Low Energy) |
|--------|-------------------------|----------------------------|
| **Device Discovery** | Bonded devices only | Active scanning |
| **Chunk Size** | 512 bytes | 100 bytes |
| **Connection** | Direct SPP connection | Service/characteristic discovery |
| **Data Transfer** | `writeBytes()` method | `write()` to characteristic |
| **Error Handling** | SPP-specific errors | BLE-specific errors |
| **Debug Messages** | SPP-focused logging | BLE-focused logging |

## 🔍 **SPP-Specific Debug Features**

- **Bonded Device Scanning**: Only shows paired devices
- **Larger Chunk Sizes**: 512-byte chunks for better performance
- **SPP Connection Status**: Direct connection monitoring
- **Classic Bluetooth Support**: Optimized for traditional thermal printers
- **Enhanced Reliability**: Better error handling for SPP connections

This comprehensive SPP logging will give you complete visibility into the Classic Bluetooth printing process and help you quickly identify and resolve any issues with your SPP thermal printer!
