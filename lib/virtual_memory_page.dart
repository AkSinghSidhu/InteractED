import 'package:flutter/material.dart';
import 'dart:async';
import 'theme_notifier.dart';

class VirtualMemoryPage extends StatefulWidget {
  const VirtualMemoryPage({super.key});

  @override
  State<VirtualMemoryPage> createState() => _VirtualMemoryPageState();
}

class _VirtualMemoryPageState extends State<VirtualMemoryPage> {
  final List<int> _requestQueue = [0x1A4, 0x2B8, 0x1A4, 0x3C2, 0x4D1, 0x5E6, 0x2B8, 0x6F9, 0x1A4, 0x7A1];
  final int _pageSize = 256;
  final int _ramSize = 4;
  final int _tlbSize = 4;

  int _currentRequestIndex = 0;
  bool _isAutoPlaying = false;
  bool _isLru = false;
  
  List<Map<String, int>> _tlb = []; 
  Map<int, int> _pageTable = {}; 
  List<int?> _ram = List.filled(4, null); 
  List<int> _disk = []; 
  
  List<int> _ramLoadTime = List.filled(4, 0); 
  List<int> _ramLastAccess = List.filled(4, 0); 
  int _logicalTime = 0;

  String _statusMessage = "Ready. Select an algorithm and start.";
  String _stepDescription = "";
  Timer? _timer;

  int _hits = 0;
  int _misses = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _stepForward() {
    if (_currentRequestIndex >= _requestQueue.length) {
      _isAutoPlaying = false;
      _timer?.cancel();
      setState(() {});
      return;
    }

    final address = _requestQueue[_currentRequestIndex];
    final vpn = (address / _pageSize).floor();
    final offset = address % _pageSize;
    _logicalTime++;

    String msg = "Request: 0x${address.toRadixString(16).toUpperCase()}";
    String details = "VPN: $vpn | Offset: 0x${offset.toRadixString(16).toUpperCase()}";

    int tlbIndex = _tlb.indexWhere((entry) => entry['vpn'] == vpn);
    
    if (tlbIndex != -1) {
      msg += " -> TLB Hit!";
      details += "\nFound translation in TLB (Cache). Direct access to RAM.";
      _hits++;
      int pfn = _tlb[tlbIndex]['pfn']!;
      _ramLastAccess[pfn] = _logicalTime;
      var entry = _tlb.removeAt(tlbIndex);
      _tlb.add(entry); 
    } else {
      msg += " -> TLB Miss";
      details += "\nNot in TLB. Checking Page Table (RAM)...";
      _misses++;
      
      if (_pageTable.containsKey(vpn) && _pageTable[vpn] != -1) {
        int pfn = _pageTable[vpn]!;
        msg += " -> Page Table Hit (Frame $pfn)";
        details += "\nFound in Page Table. Address is already in RAM Frame $pfn. Updating TLB.";
        _ramLastAccess[pfn] = _logicalTime;
        _updateTlb(vpn, pfn);
      } else {
        msg += " -> Page Fault!";
        details += "\nPage Fault! VPN $vpn is not in RAM. Must fetch from Disk.";
        _handlePageFault(vpn, (action) {
            details += "\n$action";
        });
      }
    }

    setState(() {
      _statusMessage = msg;
      _stepDescription = details;
      _currentRequestIndex++;
    });
  }

  void _handlePageFault(int vpn, Function(String) logCallback) {
    int frameIndex = _ram.indexOf(null);

    if (frameIndex != -1) {
      _ram[frameIndex] = vpn;
      _ramLoadTime[frameIndex] = _logicalTime;
      _ramLastAccess[frameIndex] = _logicalTime;
      _pageTable[vpn] = frameIndex;
      _updateTlb(vpn, frameIndex);
      logCallback("Loaded Page $vpn into empty RAM Frame $frameIndex.");
    } else {
      int victimFrame;
      if (_isLru) {
        victimFrame = 0;
        int minTime = _ramLastAccess[0];
        for(int i=1; i<_ramSize; i++) {
          if (_ramLastAccess[i] < minTime) {
            minTime = _ramLastAccess[i];
            victimFrame = i;
          }
        }
        logCallback("RAM Full. Evicting Frame $victimFrame (LRU Policy).");
      } else {
        victimFrame = 0;
        int minTime = _ramLoadTime[0];
        for(int i=1; i<_ramSize; i++) {
          if (_ramLoadTime[i] < minTime) {
            minTime = _ramLoadTime[i];
            victimFrame = i;
          }
        }
        logCallback("RAM Full. Evicting Frame $victimFrame (FIFO Policy).");
      }

      int evictedVpn = _ram[victimFrame]!;
      _pageTable[evictedVpn] = -1; 
      if (!_disk.contains(evictedVpn)) _disk.add(evictedVpn);

      _ram[victimFrame] = vpn;
      _ramLoadTime[victimFrame] = _logicalTime;
      _ramLastAccess[victimFrame] = _logicalTime;
      _pageTable[vpn] = victimFrame;
      
      _tlb.removeWhere((e) => e['vpn'] == evictedVpn);
      _updateTlb(vpn, victimFrame);
      
      logCallback("Swapped Page $evictedVpn to Disk. Loaded Page $vpn into Frame $victimFrame.");
    }
  }

  void _updateTlb(int vpn, int pfn) {
    if (_tlb.length >= _tlbSize) {
      _tlb.removeAt(0); 
    }
    _tlb.add({'vpn': vpn, 'pfn': pfn});
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _currentRequestIndex = 0;
      _isAutoPlaying = false;
      _tlb.clear();
      _pageTable.clear();
      _ram = List.filled(_ramSize, null);
      _disk.clear();
      _ramLoadTime.fillRange(0, _ramSize, 0);
      _ramLastAccess.fillRange(0, _ramSize, 0);
      _logicalTime = 0;
      _hits = 0;
      _misses = 0;
      _statusMessage = "Reset. Algorithm: ${_isLru ? 'LRU' : 'FIFO'}";
      _stepDescription = "Ready to start.";
    });
  }

  void _seekTo(double value) {
    int target = value.toInt();
    if (target == _currentRequestIndex) return;
    
    _timer?.cancel();
    _isAutoPlaying = false;
    
    bool currentAlgo = _isLru;
    _reset(); 
    _isLru = currentAlgo; 
    
    while (_currentRequestIndex < target) {
      _stepForward();
    }
  }

  void _togglePlay() {
    if (_isAutoPlaying) {
      _timer?.cancel();
      setState(() => _isAutoPlaying = false);
    } else {
      setState(() => _isAutoPlaying = true);
      _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _stepForward());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Memory Sim'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reset),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Hit Rate: ${_currentRequestIndex == 0 ? 0 : ((_hits / _currentRequestIndex) * 100).toStringAsFixed(1)}%"),
                    Row(
                      children: [
                        Text("FIFO", style: TextStyle(fontWeight: !_isLru ? FontWeight.bold : FontWeight.normal)),
                        Switch(
                          value: _isLru,
                          onChanged: (val) {
                            setState(() => _isLru = val);
                            _reset();
                          },
                        ),
                        Text("LRU", style: TextStyle(fontWeight: _isLru ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton.filled(
                      icon: Icon(_isAutoPlaying ? Icons.pause : Icons.play_arrow),
                      onPressed: _togglePlay,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Slider(
                        value: _currentRequestIndex.toDouble(),
                        min: 0,
                        max: _requestQueue.length.toDouble(),
                        divisions: _requestQueue.length,
                        label: "$_currentRequestIndex / ${_requestQueue.length}",
                        onChanged: (val) => _seekTo(val),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  _statusMessage,
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                if (_stepDescription.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _stepDescription,
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader("CPU Request Queue", colorScheme),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _requestQueue.length,
                      itemBuilder: (context, index) {
                        bool isCurrent = index == _currentRequestIndex;
                        bool isProcessed = index < _currentRequestIndex;
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isCurrent ? colorScheme.primary : (isProcessed ? colorScheme.surfaceContainerHighest : colorScheme.surface),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isCurrent ? colorScheme.primary : colorScheme.outlineVariant,
                                width: isCurrent ? 2 : 1
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "0x${_requestQueue[index].toRadixString(16).toUpperCase()}",
                                style: TextStyle(
                                    color: isCurrent ? colorScheme.onPrimary : (isProcessed ? colorScheme.onSurfaceVariant : colorScheme.onSurface),
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                              if (isCurrent) 
                                Text("Processing", style: TextStyle(fontSize: 10, color: colorScheme.onPrimary)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildHeader("TLB (Cache)", colorScheme),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: colorScheme.outlineVariant), 
                                borderRadius: BorderRadius.circular(12),
                                color: colorScheme.surface,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondaryContainer,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround, 
                                      children: [
                                        Text("VPN", style: TextStyle(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold)), 
                                        Text("PFN", style: TextStyle(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold))
                                      ]
                                    ),
                                  ),
                                  if (_tlb.isEmpty) 
                                    Padding(padding: const EdgeInsets.all(16), child: Text("-", style: TextStyle(color: colorScheme.outline))),
                                  ..._tlb.map((e) => Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)))
                                    ),
                                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text("${e['vpn']}"), Text("${e['pfn']}")])
                                  ))
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildHeader("Physical RAM", colorScheme),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _ramSize,
                              itemBuilder: (context, index) {
                                int? vpn = _ram[index];
                                return Tooltip(
                                  message: vpn != null ? "VPN: $vpn\nLoaded at t=${_ramLoadTime[index]}\nLast Used at t=${_ramLastAccess[index]}" : "Empty Frame",
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: vpn != null ? Colors.green.withOpacity(0.15) : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                      border: Border.all(color: vpn != null ? Colors.green : colorScheme.outlineVariant),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("Frame $index", style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                                        const SizedBox(height: 4),
                                        Text(vpn != null ? "VPN $vpn" : "Free", style: TextStyle(fontWeight: FontWeight.bold, color: vpn != null ? colorScheme.onSurface : colorScheme.outline)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  _buildHeader("Disk (Swap)", colorScheme),
                  Container(
                    height: 60,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: _disk.isEmpty 
                      ? Center(child: Text("Empty", style: TextStyle(color: colorScheme.outline))) 
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          children: _disk.map((v) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4), 
                            child: Chip(
                              label: Text("VPN $v"), 
                              visualDensity: VisualDensity.compact,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              side: BorderSide.none,
                            )
                          )).toList(),
                        ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)),
    );
  }
}
