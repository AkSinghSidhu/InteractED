import 'package:flutter/material.dart';
import 'dart:async';
import 'theme_notifier.dart';

class OsiModelPage extends StatefulWidget {
  const OsiModelPage({super.key});

  @override
  State<OsiModelPage> createState() => _OsiModelPageState();
}

class _OsiModelPageState extends State<OsiModelPage> {
  int _currentStep = 0;
  bool _isAutoPlaying = false;

  List<String> _packetHeaders = ["Data"];
  bool _isBinaryMode = false;

  final Set<int> _expandedLayers = {};

  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _layers = [
    {
      "layer": 7,
      "name": "Application",
      "action": "Generate Data",
      "added": "Data",
      "color": Colors.deepPurple,
      "desc": "Human-computer interaction layer, where applications access network services.",
      "protocols": "HTTP, DNS, FTP, SMTP",
      "attacks": "Phishing, SQL Injection, XSS"
    },
    {
      "layer": 6,
      "name": "Presentation",
      "action": "Encrypt & Format",
      "added": "Format",
      "color": Colors.blue,
      "desc": "Ensures data is in a usable format. Encryption and translation happen here.",
      "protocols": "SSL/TLS, JPEG, ASCII",
      "attacks": "SSL Stripping, Malformed Input"
    },
    {
      "layer": 5,
      "name": "Session",
      "action": "Start Session",
      "added": "Session ID",
      "color": Colors.teal,
      "desc": "Maintains connections and controls ports/sessions between computers.",
      "protocols": "NetBIOS, PPTP, RPC",
      "attacks": "Session Hijacking, MITM"
    },
    {
      "layer": 4,
      "name": "Transport",
      "action": "Add Ports (TCP/UDP)",
      "added": "TCP Header",
      "color": Colors.green,
      "desc": "Transmits data using protocols like TCP (reliable) and UDP (fast).",
      "protocols": "TCP, UDP",
      "attacks": "SYN Flood, Port Scanning"
    },
    {
      "layer": 3,
      "name": "Network",
      "action": "Add IP Address",
      "added": "IP Header",
      "color": Colors.orangeAccent,
      "desc": "Decides which physical path the data will take (Routing).",
      "protocols": "IP, ICMP, IPSec, Routers",
      "attacks": "IP Spoofing, Ping of Death"
    },
    {
      "layer": 2,
      "name": "Data Link",
      "action": "Add MAC Address",
      "added": "Frame",
      "color": Colors.deepOrange,
      "desc": "Defines format of data on the network (Frames). Handles physical addressing.",
      "protocols": "Ethernet, MAC, Switches",
      "attacks": "MAC Flooding, ARP Spoofing"
    },
    {
      "layer": 1,
      "name": "Physical",
      "action": "Convert to Bits",
      "added": "Bits",
      "color": Colors.red,
      "desc": "Transmission of raw bit stream over physical medium (cables, wifi).",
      "protocols": "Cables, Fiber, Hubs",
      "attacks": "Wiretapping, Jamming"
    },
  ];

  int get _activeLayerIndex {
    if (_currentStep <= 6) return _currentStep;
    if (_currentStep == 7) return 6;
    return 14 - _currentStep;
  }

  bool get _isEncapsulating => _currentStep <= 7;

  void _toggleLayerExpansion(int index) {
    setState(() {
      if (_expandedLayers.contains(index)) {
        _expandedLayers.remove(index);
      } else {
        _expandedLayers.add(index);
      }
    });
  }

  void _nextStep() {
    if (_currentStep >= 14) return;

    setState(() {
      _currentStep++;
      _updatePacketVisuals();
    });
    _scrollToActiveLayer();
  }

  void _prevStep() {
    if (_currentStep <= 0) return;

    setState(() {
      _currentStep--;
      _updatePacketVisuals();
    });
    _scrollToActiveLayer();
  }

  void _reset() {
    setState(() {
      _currentStep = 0;
      _isAutoPlaying = false;
      _packetHeaders = ["Data"];
      _isBinaryMode = false;
    });
    _scrollToActiveLayer();
  }

  void _toggleAutoPlay() {
    if (_isAutoPlaying) {
      setState(() => _isAutoPlaying = false);
      return;
    }

    setState(() => _isAutoPlaying = true);
    _runAutoPlay();
  }

  Future<void> _runAutoPlay() async {
    while (_isAutoPlaying && _currentStep < 14) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!_isAutoPlaying) break;
      _nextStep();
    }
    if (_currentStep == 14) {
      setState(() => _isAutoPlaying = false);
    }
  }

  void _updatePacketVisuals() {
    List<String> current = ["Data"];
    bool binary = false;

    int stages = _currentStep;
    if (stages > 7) stages = 14 - stages;

    if (stages >= 1) current.insert(0, "Fmt");
    if (stages >= 2) current.insert(0, "Sess");
    if (stages >= 3) current.insert(0, "TCP");
    if (stages >= 4) current.insert(0, "IP");
    if (stages >= 5) {
      current.insert(0, "MAC");
      current.add("FCS");
    }
    if (stages >= 6) {
      binary = true;
    }

    if (_currentStep == 7) binary = true;

    setState(() {
      _packetHeaders = current;
      _isBinaryMode = binary;
    });
  }

  void _scrollToActiveLayer() {
    if (_scrollController.hasClients) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeLayerIdx = _activeLayerIndex;
    final activeLayerData = _layers[activeLayerIdx];
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Interactive OSI Lab"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: "Reset Simulation",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _layers.length,
              itemBuilder: (context, index) {
                final layer = _layers[index];
                final isSimulationActive = index == activeLayerIdx;
                final isExpanded = _expandedLayers.contains(index);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: (isSimulationActive || isExpanded)
                        ? layer['color'].withOpacity(0.15)
                        : layer['color'].withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSimulationActive
                            ? layer['color']
                            : Colors.grey.shade300,
                        width: isSimulationActive ? 2.5 : 1
                    ),
                    boxShadow: isSimulationActive ? [
                      BoxShadow(
                          color: (layer['color'] as Color).withOpacity(0.25),
                          blurRadius: 8,
                          spreadRadius: 1
                      )
                    ] : [],
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _toggleLayerExpansion(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: layer['color'],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    "${layer['layer']}",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      layer['name'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: colorScheme.onSurface
                                      ),
                                    ),
                                    if (isSimulationActive)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          _isEncapsulating
                                              ? "↓ Encapsulating: Adding ${layer['added']}"
                                              : "↑ Decapsulating: Reading ${layer['added']}",
                                          style: TextStyle(
                                              color: layer['color'],
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),

                      AnimatedCrossFade(
                        firstChild: Container(height: 0),
                        secondChild: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                layer['desc'],
                                style: TextStyle(color: colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(Icons.language, "Protocols", layer['protocols'], colorScheme.primary, colorScheme.onSurface),
                              const SizedBox(height: 8),
                              _buildDetailRow(Icons.warning_amber_rounded, "Threats", layer['attacks'], Colors.redAccent, colorScheme.onSurface),
                            ],
                          ),
                        ),
                        crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5)
                  )
                ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "CURRENT PACKET STATE",
                      style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: _isBinaryMode ? Colors.redAccent : Colors.blueAccent,
                          borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text(
                        _isBinaryMode ? "PHYSICAL LINK" : "LOGICAL LINK",
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  height: 60,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: _isBinaryMode
                      ? _buildBinaryStream()
                      : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: _packetHeaders.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 4),
                    itemBuilder: (context, index) {
                      final isData = _packetHeaders[index] == "Data";
                      return _buildPacketBlock(
                          _packetHeaders[index],
                          isData ? Colors.deepPurple : Colors.grey.shade700,
                          isData
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.skip_previous_rounded,
                      onTap: _currentStep > 0 ? _prevStep : null,
                    ),
                    _buildMainActionButton(
                      activeLayerColor: activeLayerData['color'],
                    ),
                    _buildControlButton(
                      icon: Icons.skip_next_rounded,
                      onTap: _currentStep < 14 ? _nextStep : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: textColor, fontSize: 13),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPacketBlock(String label, Color color, bool isData) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: isData ? 24 : 12, vertical: 8),
      decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4)
            )
          ]
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14
        ),
      ),
    );
  }

  Widget _buildBinaryStream() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.greenAccent, width: 2)
      ),
      child: const Text(
        "10110100110100101101",
        style: TextStyle(
            fontFamily: 'Courier',
            color: Colors.greenAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2
        ),
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, VoidCallback? onTap}) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.grey.shade200 : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isEnabled ? Colors.black87 : Colors.grey.shade400),
      ),
    );
  }

  Widget _buildMainActionButton({required Color activeLayerColor}) {
    bool isFinished = _currentStep == 14;

    return GestureDetector(
      onTap: isFinished ? _reset : _toggleAutoPlay,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 64,
        width: 64,
        decoration: BoxDecoration(
            color: isFinished ? Colors.orange : (_isAutoPlaying ? Colors.redAccent : activeLayerColor),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: (isFinished ? Colors.orange : activeLayerColor).withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2
              )
            ]
        ),
        child: Icon(
          isFinished
              ? Icons.replay
              : (_isAutoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
