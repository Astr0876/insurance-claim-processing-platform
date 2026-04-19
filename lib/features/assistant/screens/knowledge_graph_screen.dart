import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/theme/neubrut_tokens.dart';
import '../models/assistant_graph_models.dart';

class NodePosition {
  double x, y;
  double vx = 0, vy = 0;
  NodePosition({required this.x, required this.y});
}

class KnowledgeGraphScreen extends StatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  State<KnowledgeGraphScreen> createState() => _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends State<KnowledgeGraphScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  KnowledgeGraphData? _data;
  final Map<String, NodePosition> _positions = {};
  bool _initialized = false;
  GraphNode? _selectedNode;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _initializePositions(KnowledgeGraphData data, Size size) {
    final random = math.Random();
    for (final node in data.nodes) {
      _positions[node.id] = NodePosition(
        x: random.nextDouble() * size.width,
        y: random.nextDouble() * size.height,
      );
    }
    _initialized = true;
  }

  void _updatePositions(Size size) {
    if (_data == null) return;

    const double repulsion = 2000.0;
    const double attraction = 0.05;
    const double damping = 0.9;

    // 1. Repulsion between all nodes
    for (final nodeA in _data!.nodes) {
      final posA = _positions[nodeA.id]!;
      for (final nodeB in _data!.nodes) {
        if (nodeA.id == nodeB.id) continue;
        final posB = _positions[nodeB.id]!;

        double dx = posA.x - posB.x;
        double dy = posA.y - posB.y;
        double distanceSq = dx * dx + dy * dy;
        if (distanceSq < 100) distanceSq = 100;
        double distance = math.sqrt(distanceSq);

        double force = repulsion / distanceSq;
        posA.vx += (dx / distance) * force;
        posA.vy += (dy / distance) * force;
      }
    }

    // 2. Attraction between connected nodes
    for (final edge in _data!.edges) {
      final posFrom = _positions[edge.from];
      final posTo = _positions[edge.to];
      if (posFrom == null || posTo == null) continue;

      double dx = posTo.x - posFrom.x;
      double dy = posTo.y - posFrom.y;
      double distance = math.sqrt(dx * dx + dy * dy);

      double force = distance * attraction * edge.weight;
      posFrom.vx += (dx / distance) * force;
      posFrom.vy += (dy / distance) * force;
      posTo.vx -= (dx / distance) * force;
      posTo.vy -= (dy / distance) * force;
    }

    // 3. Central attraction
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    for (final pos in _positions.values) {
      double dx = centerX - pos.x;
      double dy = centerY - pos.y;
      pos.vx += dx * 0.01;
      pos.vy += dy * 0.01;
    }

    // 4. Update coordinates and apply damping
    for (final pos in _positions.values) {
      pos.x += pos.vx;
      pos.y += pos.vy;
      pos.vx *= damping;
      pos.vy *= damping;

      // Keep within bounds
      pos.x = pos.x.clamp(50, size.width - 50);
      pos.y = pos.y.clamp(50, size.height - 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    _data = state.assistant.getKnowledgeGraph();

    return Scaffold(
      backgroundColor: NBColors.bg,
      appBar: AppBar(
        title: Text('KNOWLEDGE GRAPH', style: NBText.label),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(color: NBColors.black, height: 2, thickness: 2),
        ),
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              if (!_initialized && _data != null && _data!.nodes.isNotEmpty) {
                _initializePositions(_data!, size);
              }

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  _updatePositions(size);
                  return GestureDetector(
                    onTapUp: (details) {
                      _handleTap(details.localPosition);
                    },
                    child: CustomPaint(
                      size: size,
                      painter: GraphPainter(
                        data: _data!,
                        positions: _positions,
                        selectedNode: _selectedNode,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          
          if (_selectedNode != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: NBColors.black, width: 3),
                  borderRadius: NBRadius.softAll,
                  boxShadow: NBShadows.medium,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _selectedNode!.type == 'concept' ? Colors.orange : Colors.purple,
                            border: Border.all(color: NBColors.black, width: 1.5),
                          ),
                          child: Text(
                            _selectedNode!.type.toUpperCase(),
                            style: NBText.label.copyWith(color: Colors.white, fontSize: 10),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() => _selectedNode = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedNode!.label,
                      style: NBText.heading3,
                    ),
                    if (_selectedNode!.metadata.containsKey('content'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _selectedNode!.metadata['content'],
                          style: NBText.bodySmall,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: NBColors.black, width: 2),
                boxShadow: NBShadows.small,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(Colors.purple, 'Study Chunk'),
                  const SizedBox(height: 8),
                  _buildLegendItem(Colors.orange, 'Core Concept'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 8),
        Text(label, style: NBText.label.copyWith(fontSize: 10)),
      ],
    );
  }

  void _handleTap(Offset localPosition) {
    if (_data == null) return;
    
    GraphNode? tapped;
    double minDistance = 30.0;

    for (final node in _data!.nodes) {
      final pos = _positions[node.id]!;
      double distance = (Offset(pos.x, pos.y) - localPosition).distance;
      if (distance < minDistance) {
        minDistance = distance;
        tapped = node;
      }
    }

    setState(() {
      _selectedNode = tapped;
    });
  }
}

class GraphPainter extends CustomPainter {
  final KnowledgeGraphData data;
  final Map<String, NodePosition> positions;
  final GraphNode? selectedNode;

  GraphPainter({
    required this.data, 
    required this.positions,
    this.selectedNode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..strokeWidth = 1.5;

    final selectedLinePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3;

    // 1. Draw Edges
    for (final edge in data.edges) {
      final posFrom = positions[edge.from];
      final posTo = positions[edge.to];
      if (posFrom == null || posTo == null) continue;

      bool isSelected = selectedNode != null && 
          (selectedNode!.id == edge.from || selectedNode!.id == edge.to);

      canvas.drawLine(
        Offset(posFrom.x, posFrom.y),
        Offset(posTo.x, posTo.y),
        isSelected ? selectedLinePaint : linePaint,
      );
    }

    // 2. Draw Nodes
    for (final node in data.nodes) {
      final pos = positions[node.id]!;
      final isSelected = selectedNode?.id == node.id;
      
      final nodeColor = node.type == 'concept' ? Colors.orange : Colors.purple;
      
      // Node Shadow (Neubrutalist)
      canvas.drawRect(
        Rect.fromCenter(center: Offset(pos.x + 3, pos.y + 3), width: 14, height: 14),
        Paint()..color = Colors.black,
      );

      // Node Body
      final paint = Paint()
        ..color = isSelected ? Colors.yellow : nodeColor
        ..style = PaintingStyle.fill;
      
      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawRect(
        Rect.fromCenter(center: Offset(pos.x, pos.y), width: 14, height: 14),
        paint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(pos.x, pos.y), width: 14, height: 14),
        borderPaint,
      );

      // Label for concept nodes or selected node
      if (node.type == 'concept' || isSelected) {
        final textSpan = TextSpan(
          text: node.label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            backgroundColor: Colors.white.withAlpha(200),
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(pos.x + 10, pos.y - 15));
      }
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) => true;
}
