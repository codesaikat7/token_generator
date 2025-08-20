import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_print_service.dart';

class BluetoothPrinterDialog extends StatefulWidget {
  final Function(BluetoothDevice) onPrinterSelected;

  const BluetoothPrinterDialog({
    Key? key,
    required this.onPrinterSelected,
  }) : super(key: key);

  @override
  State<BluetoothPrinterDialog> createState() => _BluetoothPrinterDialogState();
}

class _BluetoothPrinterDialogState extends State<BluetoothPrinterDialog> {
  final BluetoothPrintService _bluetoothService = BluetoothPrintService();
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  BluetoothDevice?
      _connectingDevice; // Track which specific device is connecting
  String? _error;
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _checkBluetoothAndStartScan();
  }

  Future<void> _checkBluetoothAndStartScan() async {
    try {
      bool isAvailable = await _bluetoothService.isBluetoothAvailable();
      if (!isAvailable) {
        setState(() {
          _error = 'Bluetooth is not available. Please enable Bluetooth.';
        });
        return;
      }

      await _bluetoothService.requestPermissions();
      _startScan();
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize Bluetooth: $e';
      });
    }
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _devices.clear();
      _error = null;
    });

    _bluetoothService.startScan().listen((devices) {
      setState(() {
        _devices = devices;
      });
    });

    // Stop scanning after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        _bluetoothService.stopScan();
      }
    });
  }

  Future<void> _connectToPrinter(BluetoothDevice device) async {
    debugPrint('Connect button clicked for device: ${device.remoteId.str}');
    debugPrint('Current connecting device: ${_connectingDevice?.remoteId.str}');
    debugPrint('Current selected device: ${_selectedDevice?.remoteId.str}');

    // Prevent connecting if already connecting to another device
    if (_connectingDevice != null) {
      debugPrint('Already connecting to another device, returning');
      return;
    }

    // Prevent connecting if this device is already connected
    if (_selectedDevice?.remoteId.str == device.remoteId.str) {
      debugPrint('Device already connected, returning');
      return;
    }

    debugPrint('Setting connecting device to: ${device.remoteId.str}');
    setState(() {
      _connectingDevice = device;
      _error = null;
    });

    try {
      bool success = await _bluetoothService.connectToDevice(device);
      if (success) {
        setState(() {
          _selectedDevice = device;
          _connectingDevice = null;
        });

        // For testing: keep dialog open to show connected state
        // Comment out the auto-close for testing multiple printer connections
        // widget.onPrinterSelected(device);
        // Navigator.of(context).pop();
      } else {
        setState(() {
          _error = 'Failed to connect to printer';
          _connectingDevice = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _connectingDevice = null;
      });
    }
  }

  @override
  void dispose() {
    _bluetoothService.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if device is in landscape mode
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
          maxHeight: isLandscape
              ? MediaQuery.of(context).size.height *
                  0.9 // More height in landscape
              : MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          padding: EdgeInsets.all(
              isLandscape ? 12 : 16), // Less padding in landscape
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Ensure vertical alignment
                children: [
                  // Title - flexible to adapt to available space
                  Expanded(
                    child: Text(
                      'Select Printer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow
                          .ellipsis, // Handle text overflow gracefully
                    ),
                  ),
                  const SizedBox(
                      width: 8), // Space between title and right elements
                  // Right side with close button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: isLandscape ? 12 : 16),

              // Scan button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bluetooth_searching),
                  label:
                      Text(_isScanning ? 'Scanning...' : 'Scan for Printers'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              SizedBox(height: isLandscape ? 12 : 16),

              // Error display
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_error != null) SizedBox(height: isLandscape ? 12 : 16),

              // Device list
              Expanded(
                child: _devices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth_disabled,
                              size: isLandscape
                                  ? 48
                                  : 64, // Smaller icon in landscape
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: isLandscape ? 12 : 16),
                            Text(
                              _isScanning
                                  ? 'Searching for printers...'
                                  : 'No printers found',
                              style: TextStyle(
                                fontSize: isLandscape
                                    ? 14
                                    : 16, // Smaller text in landscape
                                color: Colors.grey[600],
                              ),
                            ),
                            if (!_isScanning) ...[
                              SizedBox(height: isLandscape ? 6 : 8),
                              Text(
                                'Make sure your thermal printer is turned on and discoverable',
                                style: TextStyle(
                                  fontSize: isLandscape
                                      ? 12
                                      : 14, // Smaller text in landscape
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _devices.length,
                        itemBuilder: (context, index) {
                          final device = _devices[index];
                          final isSelected = _selectedDevice?.remoteId.str ==
                              device.remoteId.str;

                          return Card(
                            margin: EdgeInsets.only(
                                bottom: isLandscape
                                    ? 6
                                    : 8), // Less margin in landscape
                            color: isSelected ? Colors.deepPurple[50] : null,
                            child: ListTile(
                              leading: Icon(
                                Icons.print,
                                color: isSelected
                                    ? Colors.deepPurple
                                    : Colors.grey[600],
                                size: isLandscape
                                    ? 20
                                    : 24, // Smaller icon in landscape
                              ),
                              title: Text(
                                _bluetoothService.getDeviceDisplayName(device),
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected ? Colors.deepPurple : null,
                                  fontSize: isLandscape
                                      ? 14
                                      : 16, // Smaller text in landscape
                                ),
                              ),
                              subtitle: Text(
                                device.remoteId.str,
                                style: TextStyle(
                                  fontSize: isLandscape
                                      ? 10
                                      : 12, // Smaller text in landscape
                                  fontFamily: 'monospace',
                                ),
                              ),
                              trailing: _connectingDevice?.remoteId.str ==
                                      device.remoteId.str
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : isSelected
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[100],
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.green[300]!),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle,
                                                  color: Colors.green[600],
                                                  size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Connected',
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ElevatedButton(
                                          onPressed: (_connectingDevice != null)
                                              ? null
                                              : () => _connectToPrinter(device),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[200],
                                            foregroundColor: Colors.grey[700],
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                          child: const Text('Connect'),
                                        ),
                              onTap: (_connectingDevice?.remoteId.str ==
                                      device.remoteId.str)
                                  ? null
                                  : () => _connectToPrinter(device),
                            ),
                          );
                        },
                      ),
              ),

              SizedBox(height: isLandscape ? 12 : 16),

              // Help text
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(
                    isLandscape ? 8 : 12), // Less padding in landscape
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.blue[600],
                      size: isLandscape ? 16 : 20, // Smaller icon in landscape
                    ),
                    SizedBox(width: isLandscape ? 6 : 8),
                    Expanded(
                      child: Text(
                        'Make sure your thermal printer is turned on, has Bluetooth enabled, and is in pairing mode.',
                        style: TextStyle(
                          fontSize: isLandscape
                              ? 10
                              : 12, // Smaller text in landscape
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Manual close button for testing
              if (_selectedDevice != null)
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: isLandscape ? 8 : 12),
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onPrinterSelected(_selectedDevice!);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Use This Printer'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
