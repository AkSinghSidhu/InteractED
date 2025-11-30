import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'theme_notifier.dart';

enum Algorithm { bfs, dfs }
enum AnimationState { stopped, playing, paused }

class Node {
  String id;
  Offset position;
  final List<String> neighbors = [];
  final AnimationController animationController;

  Node({required this.id, required this.position, required TickerProvider vsync})
      : animationController = AnimationController(
    vsync: vsync,
    duration: const Duration(milliseconds: 300),
    lowerBound: 1.0,
    upperBound: 1.3,
  );

  void dispose() {
    animationController.dispose();
  }
}

class Edge {
  final String from;
  final String to;
  const Edge(this.from, this.to);
}

class GraphVisualizerPage extends StatefulWidget {
  const GraphVisualizerPage({super.key});

  @override
  State<GraphVisualizerPage> createState() => _GraphVisualizerPageState();
}

class _GraphVisualizerPageState extends State<GraphVisualizerPage> with TickerProviderStateMixin {
  final Map<String, Node> _graph = {};
  int _nextNodeId = 0;
  bool _isAddingEdge = false;
  String? _edgeStartNodeId;
  String? _draggedNodeId;

  Algorithm _algorithm = Algorithm.bfs;
  bool _isDirected = false;
  String? _startNodeId;
  String? _endNodeId;
  AnimationState _animationState = AnimationState.stopped;
  double _speed = 1.0;
  Timer? _timer;

  final Set<String> _visited = {};
  final List<String> _frontier = [];
  String? _currentNodeId;
  Edge? _currentEdge;
  List<String> _finalPath = [];
  bool _goalFound = false;
  final Map<String, String> _parentMap = {};

  @override
  void initState() {
    super.initState();
    _resetPositions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var node in _graph.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _addNode(Offset position) {
    if (_animationState != AnimationState.stopped) return;
    setState(() {
      final id = String.fromCharCode('A'.codeUnitAt(0) + _nextNodeId++);
      _graph[id] = Node(id: id, position: position, vsync: this);
      _graph[id]?.animationController.forward(from: 0.0).then((_) => _graph[id]?.animationController.reverse());
      if (_startNodeId == null) _startNodeId = id;
    });
  }

  void _addEdge(String to) {
    if (_edgeStartNodeId != null && _edgeStartNodeId != to && !_graph[_edgeStartNodeId!]!.neighbors.contains(to)) {
      setState(() {
        _graph[_edgeStartNodeId!]!.neighbors.add(to);
        if (!_isDirected) {
          _graph[to]!.neighbors.add(_edgeStartNodeId!);
        }
      });
    }
    _toggleAddEdgeMode(false);
  }

  void _toggleAddEdgeMode(bool enabled) {
    setState(() {
      _isAddingEdge = enabled;
      if (!enabled) {
        _edgeStartNodeId = null;
      }
    });
  }

  void _clearEdges() {
    setState(() {
      for (var node in _graph.values) {
        node.neighbors.clear();
      }
    });
  }

  void _clearGraph() {
    _resetAlgorithmState();
    setState(() {
      for (var node in _graph.values) {
        node.dispose();
      }
      _graph.clear();
      _nextNodeId = 0;
      _startNodeId = null;
      _endNodeId = null;
    });
  }

  void _resetPositions() {
    _resetAlgorithmState();
    setState(() {
      for (var node in _graph.values) {
        node.dispose();
      }
      _graph.clear();
      _nextNodeId = 0;
    });

    final sample = {
      'A': const Offset(0.2, 0.2), 'B': const Offset(0.5, 0.15), 'C': const Offset(0.8, 0.2),
      'D': const Offset(0.25, 0.5), 'E': const Offset(0.5, 0.5), 'F': const Offset(0.1, 0.8), 'G': const Offset(0.8, 0.7),
    };
    sample.forEach((id, pos) {
      _graph[id] = Node(id: id, position: pos, vsync: this);
    });
    _nextNodeId = sample.length;
    _graph['A']!.neighbors.addAll(['B', 'D']); _graph['B']!.neighbors.addAll(['A', 'C', 'E']);
    _graph['C']!.neighbors.addAll(['B']); _graph['D']!.neighbors.addAll(['A', 'E', 'F']);
    _graph['E']!.neighbors.addAll(['B', 'D', 'G']); _graph['F']!.neighbors.addAll(['D']);
    _graph['G']!.neighbors.addAll(['E']);
    setState(() { _startNodeId = 'A'; });
  }

  void _updateNodePosition(String id, Offset delta, Size canvasSize) {
    setState(() {
      final newPos = _graph[id]!.position + Offset(delta.dx / canvasSize.width, delta.dy / canvasSize.height);
      _graph[id]!.position = Offset(newPos.dx.clamp(0.0, 1.0), newPos.dy.clamp(0.0, 1.0));
    });
  }

  void _resetAlgorithmState() {
    _timer?.cancel();
    setState(() {
      _animationState = AnimationState.stopped;
      _visited.clear();
      _frontier.clear();
      _currentNodeId = null;
      _currentEdge = null;
      _finalPath.clear();
      _goalFound = false;
      _parentMap.clear();
    });
  }

  void _playPause() {
    if (_startNodeId == null || _isAddingEdge) return;
    if (_animationState == AnimationState.playing) {
      _timer?.cancel();
      setState(() => _animationState = AnimationState.paused);
    } else {
      if (_animationState == AnimationState.stopped) {
        _resetAlgorithmState();
        _frontier.add(_startNodeId!);
      }
      setState(() => _animationState = AnimationState.playing);
      _timer = Timer.periodic(Duration(milliseconds: (1000 / _speed).toInt()), (timer) => _stepForward());
    }
  }

  void _stepForward() {
    if (_startNodeId == null) return;
    if (_animationState == AnimationState.stopped) {
      _resetAlgorithmState();
      _frontier.add(_startNodeId!);
      setState(() => _animationState = AnimationState.paused);
    }

    setState(() {
      while (_frontier.isNotEmpty) {
        String id = _algorithm == Algorithm.bfs ? _frontier.removeAt(0) : _frontier.removeLast();
        if (_visited.contains(id)) {
          continue;
        }

        _currentNodeId = id;
        _currentEdge = _parentMap.containsKey(id) ? Edge(_parentMap[id]!, id) : null;
        if (_graph.containsKey(id)) {
          _graph[id]?.animationController.forward(from: 0.0).then((_) => _graph[id]?.animationController.reverse());
        }
        _visited.add(id);

        if (id == _endNodeId) {
          _goalFound = true;
          _timer?.cancel();
          _traceFinalPath();
          _animationState = AnimationState.stopped;
          return;
        }

        final neighbors = List<String>.from(_graph[id]!.neighbors)..sort();
        for (final neighborId in neighbors) {
          if (!_visited.contains(neighborId) && !_frontier.contains(neighborId)) {
            _parentMap[neighborId] = id;
            _frontier.add(neighborId);
          }
        }
        return;
      }

      _timer?.cancel();
      _animationState = AnimationState.stopped;
      _currentNodeId = null;
    });
  }

  void _traceFinalPath() {
    if (!_goalFound || _endNodeId == null || _startNodeId == null) return;
    final path = <String>[];
    String? current = _endNodeId;
    while (current != null) {
      path.add(current);
      if (current == _startNodeId) break;
      current = _parentMap[current];
    }
    setState(() => _finalPath = path.reversed.toList());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Graph Traversal'),
        backgroundColor: Colors.transparent,
        centerTitle: true,
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetPositions,
            tooltip: "Reset Graph",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return isWide
              ? Row(children: [Expanded(flex: 3, child: _buildGraphCanvas(colorScheme)), Expanded(flex: 2, child: _buildControlPanel(colorScheme))])
              : Column(children: [Expanded(flex: 3, child: _buildGraphCanvas(colorScheme)), Expanded(flex: 2, child: _buildControlPanel(colorScheme))]);
        },
      ),
    );
  }

  Widget _buildGraphCanvas(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
            builder: (context, constraints) {
              final canvasSize = constraints.biggest;
              return InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 4.0,
                child: GestureDetector(
                  onTapUp: (details) {
                    if (_animationState != AnimationState.stopped) return;
                    final tapPos = details.localPosition;
                    String? tappedNodeId;
                    for (final node in _graph.values) {
                      if ((node.position.scale(canvasSize.width, canvasSize.height) - tapPos).distance < 24 * node.animationController.value) {
                        tappedNodeId = node.id;
                        break;
                      }
                    }
                    if (tappedNodeId != null) {
                      if (_isAddingEdge) {
                        if (_edgeStartNodeId == null) setState(() => _edgeStartNodeId = tappedNodeId);
                        else _addEdge(tappedNodeId);
                      }
                    } else {
                      if (_isAddingEdge) _toggleAddEdgeMode(false);
                      else _addNode(Offset(tapPos.dx / canvasSize.width, tapPos.dy / canvasSize.height));
                    }
                  },
                  onPanStart: (details) {
                    if (_animationState != AnimationState.stopped) return;
                    String? nodeId;
                    for (final node in _graph.values) {
                      if ((node.position.scale(canvasSize.width, canvasSize.height) - details.localPosition).distance < 24 * node.animationController.value) {
                        nodeId = node.id;
                        break;
                      }
                    }
                    setState(() => _draggedNodeId = nodeId);
                  },
                  onPanUpdate: (details) {
                    if (_draggedNodeId != null) _updateNodePosition(_draggedNodeId!, details.delta, canvasSize);
                  },
                  onPanEnd: (_) => setState(() => _draggedNodeId = null),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: GraphPainter(
                      graph: _graph, canvasSize: canvasSize, visited: _visited,
                      frontier: _frontier, currentNodeId: _currentNodeId,
                      currentEdge: _currentEdge, finalPath: _finalPath,
                      algorithm: _algorithm, isDirected: _isDirected,
                      edgeStartNodeId: _edgeStartNodeId,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              );
            }
        ),
      ),
    );
  }

  Widget _buildControlPanel(ColorScheme colorScheme) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildLiveMetricsCard(colorScheme),
          _buildGraphSetupCard(colorScheme),
          _buildAlgorithmCard(colorScheme),
          _buildRunControlsCard(colorScheme),
          _buildExplanationCard(colorScheme),
        ],
      ),
    );
  }

  Widget _buildLiveMetricsCard(ColorScheme colorScheme) {
    final frontierText = _algorithm == Algorithm.bfs ? _frontier.join(" → ") : _frontier.join(", ");
    return _buildSectionCard(
      colorScheme,
      title: "Live Status",
      content: Wrap(
        spacing: 16, runSpacing: 8,
        children: [
          _buildMetric("Current", _currentNodeId ?? "-", colorScheme),
          _buildMetric("Visited", _visited.length.toString(), colorScheme),
          _buildMetric("Goal", _goalFound ? "Found" : "Pending", colorScheme),
          _buildMetric(_algorithm == Algorithm.bfs ? "Queue" : "Stack", frontierText.isEmpty ? "[]" : frontierText, colorScheme),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: RichText(text: TextSpan(children: [
        TextSpan(text: '$label: ', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
        TextSpan(text: value, style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 13)),
      ])),
    );
  }

  Widget _buildGraphSetupCard(ColorScheme colorScheme) {
    return _buildSectionCard(
      colorScheme,
      title: "Tools",
      content: Wrap(
        spacing: 8, alignment: WrapAlignment.start,
        children: [
          FilledButton.tonal(
              child: Text(_isAddingEdge ? "Cancel Edge" : "Add Edge"),
              onPressed: () => _toggleAddEdgeMode(!_isAddingEdge)
          ),
          OutlinedButton(child: const Text("Clear"), onPressed: _clearGraph),
          OutlinedButton(child: const Text("Reset"), onPressed: _resetPositions),
        ],
      ),
    );
  }

  Widget _buildAlgorithmCard(ColorScheme colorScheme) {
    return _buildSectionCard(
        colorScheme,
        title: "Configuration",
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(children: [const Text("Algorithm", style: TextStyle(fontSize: 12)), const SizedBox(height: 4), _buildAlgorithmToggle(colorScheme)]),
            Column(children: [const Text("Direction", style: TextStyle(fontSize: 12)), const SizedBox(height: 4), _buildDirectedToggle(colorScheme)]),
          ],
        )
    );
  }

  Widget _buildAlgorithmToggle(ColorScheme colorScheme) {
    return ToggleButtons(
      borderRadius: BorderRadius.circular(8),
      isSelected: [_algorithm == Algorithm.bfs, _algorithm == Algorithm.dfs],
      onPressed: _animationState != AnimationState.stopped ? null : (index) => setState(() => _algorithm = index == 0 ? Algorithm.bfs : Algorithm.dfs),
      children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("BFS")), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("DFS"))],
    );
  }

  Widget _buildDirectedToggle(ColorScheme colorScheme) {
    return ToggleButtons(
      borderRadius: BorderRadius.circular(8),
      isSelected: [!_isDirected, _isDirected],
      onPressed: _animationState != AnimationState.stopped ? null : (index) {
        setState(() {
          _isDirected = index == 1;
          _clearEdges();
        });
      },
      children: const [Icon(Icons.sync_alt, size: 20), Icon(Icons.arrow_forward, size: 20)],
    );
  }

  Widget _buildRunControlsCard(ColorScheme colorScheme) {
    return _buildSectionCard(
      colorScheme,
      title: "Simulation",
      content: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDropdown("Start", _startNodeId, (val) => setState(() => _startNodeId = val))),
              const SizedBox(width: 8),
              Expanded(child: _buildDropdown("Goal", _endNodeId, (val) => setState(() => _endNodeId = val))),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Text("Speed", style: TextStyle(fontSize: 12)),
            Expanded(child: Slider(value: _speed, min: 0.5, max: 5.0, divisions: 9, label: "${_speed.toStringAsFixed(1)}x", onChanged: (v) => setState(() => _speed = v))),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton.filled(
                  icon: Icon(_animationState == AnimationState.playing ? Icons.pause : Icons.play_arrow),
                  onPressed: _playPause,
                  tooltip: "Play/Pause"
              ),
              IconButton.filledTonal(
                  icon: const Icon(Icons.skip_next),
                  onPressed: _animationState == AnimationState.playing ? null : _stepForward,
                  tooltip: "Step"
              ),
              IconButton.outlined(
                  icon: const Icon(Icons.refresh),
                  onPressed: _resetAlgorithmState,
                  tooltip: "Restart"
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDropdown(String hint, String? value, ValueChanged<String?> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: const Text("Select"),
          value: value,
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: "", child: Text("None")),
            ..._graph.keys.map((id) => DropdownMenuItem(value: id, child: Text(id))),
          ],
          onChanged: _animationState != AnimationState.stopped
              ? null
              : (val) => onChanged(val == "" ? null : val),
        ),
      ),
    );
  }

  Widget _buildExplanationCard(ColorScheme colorScheme) {
    return _buildSectionCard(
        colorScheme,
        title: "About Algorithm",
        content: AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _algorithm == Algorithm.bfs ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Text("BFS (Breadth-First Search) explores all neighbor nodes at the present depth prior to moving on to nodes at the next depth level. It uses a Queue (FIFO).", style: TextStyle(color: colorScheme.onSurfaceVariant)),
          secondChild: Text("DFS (Depth-First Search) explores as far as possible along each branch before backtracking. It uses a Stack (LIFO).", style: TextStyle(color: colorScheme.onSurfaceVariant)),
        )
    );
  }

  Widget _buildSectionCard(ColorScheme colorScheme, {required String title, required Widget content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary)),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  final Map<String, Node> graph;
  final Size canvasSize;
  final Set<String> visited;
  final List<String> frontier;
  final String? currentNodeId;
  final Edge? currentEdge;
  final List<String> finalPath;
  final Algorithm algorithm;
  final bool isDirected;
  final String? edgeStartNodeId;
  final ColorScheme colorScheme;

  GraphPainter({
    required this.graph, required this.canvasSize,
    required this.visited, required this.frontier,
    this.currentNodeId, this.currentEdge,
    required this.finalPath, required this.algorithm,
    required this.isDirected, this.edgeStartNodeId,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = colorScheme.outline.withOpacity(0.1)..strokeWidth = 1.0;
    for (int i = 1; i < 10; i++) {
      canvas.drawLine(Offset(0, i * canvasSize.height/10), Offset(canvasSize.width, i*canvasSize.height/10), gridPaint);
      canvas.drawLine(Offset(i * canvasSize.width/10, 0), Offset(i*canvasSize.width/10, canvasSize.height), gridPaint);
    }

    graph.forEach((id, node) {
      for (final neighborId in node.neighbors) {
        if (graph.containsKey(neighborId)) {
          _drawEdge(canvas, node, graph[neighborId]!);
        }
      }
    });

    graph.forEach((id, node) => _drawNode(canvas, node));
  }

  void _drawEdge(Canvas canvas, Node fromNode, Node toNode) {
    final p1 = fromNode.position.scale(canvasSize.width, canvasSize.height);
    final p2 = toNode.position.scale(canvasSize.width, canvasSize.height);

    bool isCurrent = (currentEdge?.from == fromNode.id && currentEdge?.to == toNode.id) ||
        (!isDirected && currentEdge?.from == toNode.id && currentEdge?.to == fromNode.id);
    bool isPath = finalPath.contains(fromNode.id) && finalPath.contains(toNode.id);

    final paint = Paint()
      ..strokeWidth = isPath ? 4.0 : 2.0
      ..color = isPath ? Colors.amber : (isCurrent ? colorScheme.primary : colorScheme.outline.withOpacity(0.3));

    if (isCurrent) {
      final glowPaint = Paint()..color = colorScheme.primary.withOpacity(0.5)..strokeWidth = 6..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawLine(p1, p2, glowPaint);
    }
    canvas.drawLine(p1, p2, paint);

    if (isDirected) {
      final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
      final arrowSize = 10.0;
      final p2Adjusted = p2 - Offset(math.cos(angle), math.sin(angle)) * 24.0;
      final arrowPath = Path()
        ..moveTo(p2Adjusted.dx - arrowSize * math.cos(angle - math.pi / 6), p2Adjusted.dy - arrowSize * math.sin(angle - math.pi / 6))
        ..lineTo(p2Adjusted.dx, p2Adjusted.dy)
        ..lineTo(p2Adjusted.dx - arrowSize * math.cos(angle + math.pi / 6), p2Adjusted.dy - arrowSize * math.sin(angle + math.pi / 6));

      final arrowPaint = Paint()..color = paint.color..strokeWidth = paint.strokeWidth..style = PaintingStyle.stroke;
      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  void _drawNode(Canvas canvas, Node node) {
    Color color = colorScheme.surfaceContainerHighest;
    if (node.id == edgeStartNodeId) color = colorScheme.primary;
    else if (finalPath.contains(node.id)) color = Colors.amber;
    else if (node.id == currentNodeId) color = Colors.amber.shade700;
    else if (visited.contains(node.id)) color = colorScheme.secondary;
    else if (frontier.contains(node.id)) color = algorithm == Algorithm.bfs ? Colors.green : Colors.orange;

    final center = node.position.scale(canvasSize.width, canvasSize.height);
    final radius = 24.0 * node.animationController.value;

    if (finalPath.contains(node.id)) {
      final glowPaint = Paint()..color = Colors.amber.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
      canvas.drawCircle(center, radius, glowPaint);
    }

    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawCircle(center, radius, Paint()..color = colorScheme.outline.withOpacity(0.5)..style=PaintingStyle.stroke..strokeWidth=1);

    final textPainter = TextPainter(
        text: TextSpan(text: node.id, style: TextStyle(color: _isDark(color) ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  bool _isDark(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark;
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) => true;
}
