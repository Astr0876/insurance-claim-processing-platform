/**
 * Lumina Study Hub — Backend Server
 * Express + Socket.io
 */

const express = require('express');
const { createServer } = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
});

app.use(cors());
app.use(express.json());

// ─────────────────────────────────────────────────────────────────
//  IN-MEMORY STORE  (replace with DB for production)
// ─────────────────────────────────────────────────────────────────

const rooms = {};      // roomId -> Room
const messages = {};   // roomId -> Message[]
const files = {};      // roomId -> File[]
const activity = {};   // roomId -> Activity[]
const docs = {};       // roomId -> { content, version }
const polls = {};      // roomId -> Poll[]
const sessions = {};   // roomId -> StudySession
const presence = {};   // roomId -> { userId -> PresenceInfo }
const pinnedItems = {}; // roomId -> PinnedItem[]

function getRoom(id) { return rooms[id]; }
function ensureArrays(roomId) {
  if (!messages[roomId])    messages[roomId]    = [];
  if (!files[roomId])       files[roomId]       = [];
  if (!activity[roomId])    activity[roomId]    = [];
  if (!polls[roomId])       polls[roomId]       = [];
  if (!pinnedItems[roomId]) pinnedItems[roomId] = [];
  if (!docs[roomId])        docs[roomId]        = { content: '', version: 0 };
  if (!presence[roomId])    presence[roomId]    = {};
}

function addActivity(roomId, userId, action, metadata = {}) {
  ensureArrays(roomId);
  const item = { id: uuidv4(), roomId, userId, action, metadata, timestamp: new Date().toISOString() };
  activity[roomId].unshift(item);
  if (activity[roomId].length > 100) activity[roomId].pop();
  return item;
}

// ─────────────────────────────────────────────────────────────────
//  REST ROUTES
// ─────────────────────────────────────────────────────────────────

/** POST /rooms/create */
app.post('/rooms/create', (req, res) => {
  const { name, ownerId, ownerName } = req.body;
  if (!name || !ownerId) return res.status(400).json({ error: 'name and ownerId required' });

  const room = {
    id: uuidv4(),
    name,
    ownerId,
    members: [{ userId: ownerId, name: ownerName || 'User', role: 'admin', joinedAt: new Date().toISOString() }],
    code: Math.random().toString(36).substring(2, 8).toUpperCase(),
    createdAt: new Date().toISOString(),
  };
  rooms[room.id] = room;
  ensureArrays(room.id);
  addActivity(room.id, ownerId, 'room_created', { roomName: name });
  res.json({ room });
});

/** POST /rooms/join */
app.post('/rooms/join', (req, res) => {
  const { code, userId, userName } = req.body;
  const room = Object.values(rooms).find(r => r.code === code?.toUpperCase());
  if (!room) return res.status(404).json({ error: 'Room not found' });

  const existing = room.members.find(m => m.userId === userId);
  if (!existing) {
    room.members.push({ userId, name: userName || 'User', role: 'viewer', joinedAt: new Date().toISOString() });
    addActivity(room.id, userId, 'member_joined', { userName });
  }
  ensureArrays(room.id);
  res.json({ room });
});

/** GET /rooms/:roomId */
app.get('/rooms/:roomId', (req, res) => {
  const room = getRoom(req.params.roomId);
  if (!room) return res.status(404).json({ error: 'Room not found' });
  ensureArrays(room.id);
  res.json({
    room,
    messages: messages[room.id] || [],
    files: files[room.id] || [],
    activity: activity[room.id] || [],
    polls: polls[room.id] || [],
    pinnedItems: pinnedItems[room.id] || [],
    doc: docs[room.id] || { content: '', version: 0 },
    studySession: sessions[room.id] || null,
    presence: presence[room.id] || {},
  });
});

/** GET /rooms — list all (demo) */
app.get('/rooms', (req, res) => {
  res.json({ rooms: Object.values(rooms) });
});

/** POST /messages/send */
app.post('/messages/send', (req, res) => {
  const { roomId, senderId, senderName, content, type = 'text' } = req.body;
  if (!roomId || !senderId || !content) return res.status(400).json({ error: 'Missing fields' });
  if (!rooms[roomId]) return res.status(404).json({ error: 'Room not found' });
  ensureArrays(roomId);

  const msg = { id: uuidv4(), roomId, senderId, senderName, content, type, createdAt: new Date().toISOString(), deliveredTo: [], readBy: [] };
  messages[roomId].push(msg);
  addActivity(roomId, senderId, 'message_sent', { preview: content.slice(0, 40) });
  io.to(roomId).emit('receive_message', msg);
  res.json({ message: msg });
});

/** GET /activity/:roomId */
app.get('/activity/:roomId', (req, res) => {
  const { roomId } = req.params;
  res.json({ activity: activity[roomId] || [] });
});

/** POST /polls/create */
app.post('/polls/create', (req, res) => {
  const { roomId, creatorId, question } = req.body;
  if (!rooms[roomId]) return res.status(404).json({ error: 'Room not found' });
  ensureArrays(roomId);
  const poll = { id: uuidv4(), roomId, creatorId, question, yes: [], no: [], createdAt: new Date().toISOString() };
  polls[roomId].push(poll);
  addActivity(roomId, creatorId, 'poll_created', { question });
  io.to(roomId).emit('poll_update', { type: 'new', poll });
  res.json({ poll });
});

/** POST /polls/vote */
app.post('/polls/vote', (req, res) => {
  const { roomId, pollId, userId, vote } = req.body;
  ensureArrays(roomId);
  const poll = polls[roomId]?.find(p => p.id === pollId);
  if (!poll) return res.status(404).json({ error: 'Poll not found' });
  poll.yes = poll.yes.filter(u => u !== userId);
  poll.no  = poll.no.filter(u => u !== userId);
  if (vote === 'yes') poll.yes.push(userId);
  else poll.no.push(userId);
  io.to(roomId).emit('poll_update', { type: 'vote', poll });
  res.json({ poll });
});

/** POST /pin */
app.post('/pin', (req, res) => {
  const { roomId, userId, itemType, content, label } = req.body;
  if (!rooms[roomId]) return res.status(404).json({ error: 'Room not found' });
  ensureArrays(roomId);
  const pin = { id: uuidv4(), roomId, userId, itemType, content, label, pinnedAt: new Date().toISOString() };
  pinnedItems[roomId].unshift(pin);
  addActivity(roomId, userId, 'item_pinned', { label });
  io.to(roomId).emit('pin_update', pin);
  res.json({ pin });
});

// ─────────────────────────────────────────────────────────────────
//  SOCKET.IO
// ─────────────────────────────────────────────────────────────────

io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);

  /** join_room */
  socket.on('join_room', ({ roomId, userId, userName }) => {
    socket.join(roomId);
    socket.data.roomId = roomId;
    socket.data.userId = userId;
    socket.data.userName = userName;

    ensureArrays(roomId);
    presence[roomId][userId] = { userId, userName, status: 'active', lastSeen: new Date().toISOString(), socketId: socket.id };
    io.to(roomId).emit('presence_update', { presence: Object.values(presence[roomId]) });

    const msg = { id: uuidv4(), roomId, senderId: 'system', senderName: 'System', content: `${userName} joined the room`, type: 'system', createdAt: new Date().toISOString(), deliveredTo: [], readBy: [] };
    messages[roomId].push(msg);
    io.to(roomId).emit('receive_message', msg);

    const act = addActivity(roomId, userId, 'member_joined', { userName });
    io.to(roomId).emit('activity_update', act);

    // Send current state to joining user
    socket.emit('room_state', {
      messages: messages[roomId] || [],
      presence: Object.values(presence[roomId] || {}),
      doc: docs[roomId] || { content: '', version: 0 },
      polls: polls[roomId] || [],
      pinnedItems: pinnedItems[roomId] || [],
      studySession: sessions[roomId] || null,
      activity: (activity[roomId] || []).slice(0, 30),
    });
  });

  /** send_message */
  socket.on('send_message', ({ roomId, senderId, senderName, content, type = 'text' }) => {
    ensureArrays(roomId);
    const msg = { id: uuidv4(), roomId, senderId, senderName, content, type, createdAt: new Date().toISOString(), deliveredTo: [], readBy: [] };
    messages[roomId].push(msg);
    io.to(roomId).emit('receive_message', msg);
    const act = addActivity(roomId, senderId, 'message_sent', { preview: content.slice(0, 40) });
    io.to(roomId).emit('activity_update', act);
  });

  /** typing */
  socket.on('typing', ({ roomId, userId, userName, isTyping }) => {
    socket.to(roomId).emit('typing', { userId, userName, isTyping });
  });

  /** read_receipt */
  socket.on('read_receipt', ({ roomId, userId, messageId }) => {
    ensureArrays(roomId);
    const msg = messages[roomId].find(m => m.id === messageId);
    if (msg && !msg.readBy.includes(userId)) {
      msg.readBy.push(userId);
      io.to(roomId).emit('read_receipt', { messageId, userId });
    }
  });

  /** presence_update */
  socket.on('presence_ping', ({ roomId, userId, status }) => {
    if (presence[roomId]?.[userId]) {
      presence[roomId][userId].status = status;
      presence[roomId][userId].lastSeen = new Date().toISOString();
      io.to(roomId).emit('presence_update', { presence: Object.values(presence[roomId]) });
    }
  });

  /** doc_update (last-write-wins) */
  socket.on('doc_update', ({ roomId, userId, content, version }) => {
    ensureArrays(roomId);
    if (version >= (docs[roomId]?.version || 0)) {
      docs[roomId] = { content, version, lastEditBy: userId, lastEditAt: new Date().toISOString() };
      socket.to(roomId).emit('doc_update', { content, version, lastEditBy: userId });
      const act = addActivity(roomId, userId, 'doc_edited', {});
      socket.to(roomId).emit('activity_update', act);
    }
  });

  /** session_update */
  socket.on('session_start', ({ roomId, userId }) => {
    ensureArrays(roomId);
    if (!sessions[roomId]) {
      sessions[roomId] = { roomId, startedBy: userId, startedAt: new Date().toISOString(), activeUsers: [] };
    }
    if (!sessions[roomId].activeUsers.includes(userId)) {
      sessions[roomId].activeUsers.push(userId);
    }
    io.to(roomId).emit('session_update', sessions[roomId]);
    const act = addActivity(roomId, userId, 'session_started', {});
    io.to(roomId).emit('activity_update', act);
  });

  socket.on('session_stop', ({ roomId, userId }) => {
    if (sessions[roomId]) {
      sessions[roomId].activeUsers = sessions[roomId].activeUsers.filter(u => u !== userId);
      if (sessions[roomId].activeUsers.length === 0) {
        sessions[roomId] = null;
      }
      io.to(roomId).emit('session_update', sessions[roomId]);
    }
  });

  /** poll */
  socket.on('poll_vote', ({ roomId, pollId, userId, vote }) => {
    ensureArrays(roomId);
    const poll = polls[roomId]?.find(p => p.id === pollId);
    if (!poll) return;
    poll.yes = poll.yes.filter(u => u !== userId);
    poll.no  = poll.no.filter(u => u !== userId);
    if (vote === 'yes') poll.yes.push(userId);
    else poll.no.push(userId);
    io.to(roomId).emit('poll_update', { type: 'vote', poll });
  });

  /** disconnect */
  socket.on('disconnect', () => {
    const { roomId, userId, userName } = socket.data;
    if (roomId && userId && presence[roomId]?.[userId]) {
      presence[roomId][userId].status = 'offline';
      io.to(roomId).emit('presence_update', { presence: Object.values(presence[roomId]) });
    }
    console.log('Client disconnected:', socket.id);
  });
});

// ─────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => console.log(`🚀 Lumina Study Hub server running on port ${PORT}`));
