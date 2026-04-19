class GraphNode {
  final String id;
  final String label;
  final String type; // 'document', 'chunk', 'concept'
  final Map<String, dynamic> metadata;

  GraphNode({
    required this.id, 
    required this.label, 
    required this.type, 
    this.metadata = const {},
  });
}

class GraphEdge {
  final String from;
  final String to;
  final double weight;

  GraphEdge({
    required this.from, 
    required this.to, 
    required this.weight,
  });
}

class KnowledgeGraphData {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  KnowledgeGraphData({
    required this.nodes, 
    required this.edges,
  });
}
