class AppConstants {
  static const String appName = 'LUMINA';
  static const String appTagline = 'Your Proactive Student Sidekick';
  static const double attendanceThreshold = 75.0;
  
  // Demo timetable data
  static const List<Map<String, dynamic>> demoTimetable = [
    {
      'day': 'Monday',
      'classes': [
        {'subject': 'Data Structures', 'time': '9:00 AM', 'room': 'LH-201', 'duration': 60},
        {'subject': 'Operating Systems', 'time': '11:00 AM', 'room': 'LH-305', 'duration': 60},
        {'subject': 'DBMS Lab', 'time': '2:00 PM', 'room': 'Lab-4', 'duration': 120},
      ],
    },
    {
      'day': 'Tuesday',
      'classes': [
        {'subject': 'Computer Networks', 'time': '9:00 AM', 'room': 'LH-101', 'duration': 60},
        {'subject': 'Data Structures', 'time': '11:00 AM', 'room': 'LH-201', 'duration': 60},
        {'subject': 'Mathematics III', 'time': '1:00 PM', 'room': 'LH-102', 'duration': 60},
      ],
    },
    {
      'day': 'Wednesday',
      'classes': [
        {'subject': 'Operating Systems', 'time': '10:00 AM', 'room': 'LH-305', 'duration': 60},
        {'subject': 'Software Engineering', 'time': '12:00 PM', 'room': 'LH-201', 'duration': 60},
        {'subject': 'CN Lab', 'time': '2:00 PM', 'room': 'Lab-2', 'duration': 120},
      ],
    },
    {
      'day': 'Thursday',
      'classes': [
        {'subject': 'Mathematics III', 'time': '9:00 AM', 'room': 'LH-102', 'duration': 60},
        {'subject': 'Computer Networks', 'time': '11:00 AM', 'room': 'LH-101', 'duration': 60},
        {'subject': 'Data Structures', 'time': '2:00 PM', 'room': 'LH-201', 'duration': 60},
      ],
    },
    {
      'day': 'Friday',
      'classes': [
        {'subject': 'Software Engineering', 'time': '9:00 AM', 'room': 'LH-201', 'duration': 60},
        {'subject': 'Operating Systems', 'time': '11:00 AM', 'room': 'LH-305', 'duration': 60},
        {'subject': 'DS Lab', 'time': '2:00 PM', 'room': 'Lab-3', 'duration': 120},
      ],
    },
  ];

  // Demo attendance data
  static const Map<String, Map<String, int>> demoAttendance = {
    'Data Structures': {'attended': 18, 'total': 24},
    'Operating Systems': {'attended': 14, 'total': 20},
    'Computer Networks': {'attended': 10, 'total': 16},
    'Mathematics III': {'attended': 12, 'total': 14},
    'Software Engineering': {'attended': 8, 'total': 10},
    'DBMS Lab': {'attended': 6, 'total': 8},
    'CN Lab': {'attended': 7, 'total': 8},
    'DS Lab': {'attended': 5, 'total': 8},
  };

  // Demo PDF content for assistant
  static const String demoPdfContent = '''
Chapter 1: Data Structures and Algorithms

A data structure is a way of organizing and storing data so that it can be accessed and modified efficiently. Common data structures include arrays, linked lists, stacks, queues, trees, graphs, and hash tables.

Arrays: An array is a collection of items stored at contiguous memory locations. The idea is to store multiple items of the same type together. This makes it easier to calculate the position of each element by simply adding an offset.

Linked Lists: A linked list is a linear data structure where each element is a separate object. Each element or node contains data and a reference to the next node in the sequence. Types include singly linked list, doubly linked list, and circular linked list.

Stacks: A stack is a linear data structure that follows the LIFO (Last In First Out) principle. The main operations are push (adds to top), pop (removes from top), and peek (returns top element). Stacks are used in expression evaluation, backtracking, and function call management.

Queues: A queue is a linear data structure that follows the FIFO (First In First Out) principle. Main operations include enqueue (adds to rear) and dequeue (removes from front). Queues are used in scheduling, BFS traversal, and buffering.

Trees: A tree is a hierarchical data structure consisting of nodes. The topmost node is called the root. Binary trees have at most two children per node. Binary Search Trees (BST) maintain ordering property. AVL trees and Red-Black trees are self-balancing BSTs.

Graphs: A graph consists of vertices and edges. Graphs can be directed or undirected, weighted or unweighted. Common algorithms include BFS, DFS, Dijkstra's algorithm, and Bellman-Ford. Graphs are used in social networks, maps, and recommendation systems.

Hash Tables: A hash table maps keys to values using a hash function. Collision resolution strategies include chaining and open addressing. Average time complexity for search, insert, delete is O(1). Hash tables are used in databases, caches, and symbol tables.

Chapter 2: Operating Systems

An operating system is system software that manages computer hardware and software resources. Key concepts include process management, memory management, file systems, and I/O management.

Process Management: A process is a program in execution. Process states include new, ready, running, waiting, and terminated. Context switching allows the CPU to switch between processes. Scheduling algorithms include FCFS, SJF, Priority, and Round Robin.

Memory Management: The OS manages allocation and deallocation of memory. Techniques include paging, segmentation, and virtual memory. Page replacement algorithms include FIFO, LRU, and Optimal. Memory management handles fragmentation through compaction and paging.

Deadlocks: A deadlock occurs when processes are waiting for resources held by each other. Four conditions: mutual exclusion, hold and wait, no preemption, circular wait. Prevention strategies include resource ordering and banker's algorithm.

File Systems: A file system organizes data on storage devices. Common file systems include FAT32, NTFS, ext4, and APFS. File allocation methods include contiguous, linked, and indexed allocation.

Chapter 3: Computer Networks

Computer networks enable communication between devices. The OSI model has 7 layers: Physical, Data Link, Network, Transport, Session, Presentation, Application.

TCP/IP Model: Has 4 layers - Network Access, Internet, Transport, and Application. TCP provides reliable, connection-oriented communication. UDP provides unreliable, connectionless communication.

IP Addressing: IPv4 uses 32-bit addresses. IPv6 uses 128-bit addresses. Subnetting divides networks into smaller segments. CIDR notation represents IP addresses and subnet masks.

Routing: Routing protocols determine the best path for data. Distance vector protocols include RIP. Link state protocols include OSPF. BGP is used for inter-domain routing.

HTTP: Hypertext Transfer Protocol is the foundation of the web. HTTP methods include GET, POST, PUT, DELETE. Status codes include 200 (OK), 404 (Not Found), 500 (Server Error). HTTPS adds TLS encryption for security.

DNS: Domain Name System translates domain names to IP addresses. DNS uses hierarchical naming. Record types include A, AAAA, CNAME, MX, and NS records.

Chapter 4: Database Management Systems

A DBMS manages databases and provides an interface for data manipulation. The relational model uses tables with rows and columns.

SQL: Structured Query Language includes DDL, DML, DCL, and TCL. Key commands include SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP. Joins combine data from multiple tables: INNER JOIN, LEFT JOIN, RIGHT JOIN, FULL JOIN.

Normalization: Reduces data redundancy. Normal forms include 1NF, 2NF, 3NF, BCNF. Functional dependencies determine normalization level.

Transactions: ACID properties ensure reliability: Atomicity, Consistency, Isolation, Durability. Concurrency control uses locks and timestamps. Transaction isolation levels include Read Uncommitted, Read Committed, Repeatable Read, and Serializable.

Indexing: B-trees and B+ trees are common index structures. Hash indexing provides O(1) lookup. Clustered vs non-clustered indexes affect physical data arrangement.

Chapter 5: Software Engineering

Software engineering applies engineering principles to software development. SDLC models include Waterfall, Agile, Spiral, and V-Model.

Agile: Emphasizes iterative development and collaboration. Scrum uses sprints, daily standups, and retrospectives. Kanban visualizes workflow. User stories capture requirements from user perspective.

Testing: Types include unit testing, integration testing, system testing, and acceptance testing. Test-driven development writes tests before code. Code coverage measures testing completeness.

Design Patterns: Creational patterns include Singleton, Factory, Builder. Structural patterns include Adapter, Decorator, Facade. Behavioral patterns include Observer, Strategy, Command.
''';
}
