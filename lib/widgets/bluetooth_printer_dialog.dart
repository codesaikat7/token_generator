import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../services/bluetooth_print_service.dart';

class BluetoothPrinterDialog extends StatefulWidget {
  final Function(BluetoothDevice) onPrinterSelected;

  const BluetoothPrinterDialog({
    super.key,
    required this.onPrinterSelected,
  });

  @override
  State<BluetoothPrinterDialog> createState() => _BluetoothPrinterDialogState();
}

class _BluetoothPrinterDialogState extends State<BluetoothPrinterDialog> {
  final BluetoothPrintService _bluetoothService = BluetoothPrintService();
  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  BluetoothDevice? _connectingDevice;
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
    if (!mounted) return;

    setState(() {
      _isScanning = true;
      _devices.clear();
      _error = null;
    });

    _bluetoothService.startScan().listen((devices) {
      if (mounted) {
        setState(() {
          _devices = devices.toList();
        });
      }
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
    if (!mounted) return;

    debugPrint('Connect button clicked for device: ${device.address}');
    debugPrint('Current connecting device: ${_connectingDevice?.address}');
    debugPrint('Current selected device: ${_selectedDevice?.address}');

    // Prevent connecting if already connecting to another device
    if (_connectingDevice != null) {
      debugPrint('Already connecting to another device, returning');
      return;
    }

    // Prevent connecting if this device is already connected
    if (_selectedDevice?.address == device.address) {
      debugPrint('Device already connected, returning');
      return;
    }

    debugPrint('Setting connecting device to: ${device.address}');
    if (mounted) {
      setState(() {
        _connectingDevice = device;
        _error = null;
      });
    }

    try {
      debugPrint('Attempting to connect to device: ${device.address}');
      bool success = await _bluetoothService.connectToDevice(device);

      if (mounted) {
        if (success) {
          setState(() {
            _selectedDevice = device;
            _connectingDevice = null;
            _error = null;
          });
          debugPrint('Successfully connected to device: ${device.address}');
        } else {
          setState(() {
            _connectingDevice = null;
            _error =
                'Failed to connect to ${device.name ?? "Unknown Device"}. Please try again.';
          });
          debugPrint('Failed to connect to device: ${device.address}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectingDevice = null;
          _error = 'Connection error: $e';
        });
      }
      debugPrint('Exception during connection: $e');
    }
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
                  const Expanded(
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

              SizedBox(height: isLandscape ? 8 : 12),

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
                                  ? 'Searching for SPP printers...'
                                  : 'No SPP printers found',
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
                                'Make sure your thermal printer is paired with your device first',
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
                          final isSelected =
                              _selectedDevice?.address == device.address;

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
                                device.name ?? 'Unknown Device',
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    device.address ?? 'Unknown Address',
                                    style: TextStyle(
                                      fontSize: isLandscape
                                          ? 10
                                          : 12, // Smaller text in landscape
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              trailing: _connectingDevice?.address ==
                                      device.address
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
                              onTap:
                                  (_connectingDevice?.address == device.address)
                                      ? null
                                      : () => _connectToPrinter(device),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 16),

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
                        'SPP devices must be paired first. If you don\'t see your printer, pair it in Bluetooth settings.',
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

              // Use This Printer button (when a device is connected)
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
                    child: const Text('Use This Printer'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
