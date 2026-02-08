package main

import (
	"encoding/binary"
	"log"
	"net/http"
	"sync"
	"sync/atomic"
	"time"

	"github.com/gorilla/websocket"
)

// first byte of every message is the relay control
const (
	MsgTypeJoinRoom   byte = 1  // Client -> Server: join/create room
	MsgTypeRoomJoined byte = 2  // Server -> Client: you joined, here's your peer ID
	MsgTypePeerJoined byte = 3  // Server -> Client: another peer joined
	MsgTypePeerLeft   byte = 4  // Server -> Client: a peer disconnected
	MsgTypeRoomClosed byte = 5  // Server -> Client: room closed (host left)
	MsgTypeData       byte = 10 // Bidirectional: game data relay
)

// Special peer IDs
const (
	PeerIDServer    uint32 = 1 // Host/server peer ID (Godot convention)
	PeerIDBroadcast uint32 = 0 // Send to all peers
)

type Peer struct {
	ID   uint32
	Conn *websocket.Conn
	Room *Room
	mu   sync.Mutex
}

func (p *Peer) Send(data []byte) error {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.Conn.WriteMessage(websocket.BinaryMessage, data)
}

type Room struct {
	Code       string
	Peers      map[uint32]*Peer
	NextPeerID uint32
	mu         sync.RWMutex
}

func NewRoom(code string) *Room {
	return &Room{
		Code:       code,
		Peers:      make(map[uint32]*Peer),
		NextPeerID: PeerIDServer, // first peer is host and gets ID 1
	}
}

func (r *Room) AddPeer(peer *Peer) uint32 {
	r.mu.Lock()
	defer r.mu.Unlock()

	peerID := r.NextPeerID
	r.NextPeerID++

	peer.ID = peerID
	peer.Room = r
	r.Peers[peerID] = peer

	return peerID
}

func (r *Room) RemovePeer(peerID uint32) {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.Peers, peerID)
}

func (r *Room) Broadcast(data []byte, excludePeerID uint32) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	for id, peer := range r.Peers {
		if id != excludePeerID {
			peer.Send(data)
		}
	}
}

func (r *Room) SendTo(peerID uint32, data []byte) {
	r.mu.RLock()
	peer, ok := r.Peers[peerID]
	r.mu.RUnlock()

	if ok {
		peer.Send(data)
	}
}

func (r *Room) IsEmpty() bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return len(r.Peers) == 0
}

func (r *Room) GetPeerIDs() []uint32 {
	r.mu.RLock()
	defer r.mu.RUnlock()

	ids := make([]uint32, 0, len(r.Peers))
	for id := range r.Peers {
		ids = append(ids, id)
	}
	return ids
}

type Server struct {
	rooms     map[string]*Room
	roomsMu   sync.RWMutex
	upgrader  websocket.Upgrader
	connCount atomic.Int64
}

func NewServer() *Server {
	return &Server{
		rooms: make(map[string]*Room),
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true
			},
		},
	}
}

func (s *Server) GetOrCreateRoom(code string) *Room {
	s.roomsMu.Lock()
	defer s.roomsMu.Unlock()

	room, ok := s.rooms[code]
	if !ok {
		room = NewRoom(code)
		s.rooms[code] = room
		log.Printf("Created room: %s", code)
	}
	return room
}

func (s *Server) CleanupRoom(code string) {
	s.roomsMu.Lock()
	defer s.roomsMu.Unlock()

	if room, ok := s.rooms[code]; ok && room.IsEmpty() {
		delete(s.rooms, code)
		log.Printf("Deleted empty room: %s", code)
	}
}

func (s *Server) HandleConnection(w http.ResponseWriter, r *http.Request) {
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Upgrade error: %v", err)
		return
	}

	connID := s.connCount.Add(1)
	log.Printf("New connection #%d from %s", connID, r.RemoteAddr)

	peer := &Peer{Conn: conn}
	defer s.cleanupPeer(peer)

	for {
		_, data, err := conn.ReadMessage()
		if err != nil {
			log.Printf("Read error (conn #%d): %v", connID, err)
			return
		}

		if len(data) < 1 {
			continue
		}

		msgType := data[0]
		payload := data[1:]

		switch msgType {
		case MsgTypeJoinRoom:
			s.handleJoinRoom(peer, payload)
		case MsgTypeData:
			s.handleData(peer, payload)
		}
	}
}

func (s *Server) handleJoinRoom(peer *Peer, payload []byte) {
	// Payload is the room code as a string
	roomCode := string(payload)
	if roomCode == "" {
		roomCode = "default"
	}

	room := s.GetOrCreateRoom(roomCode)
	existingPeerIDs := room.GetPeerIDs()
	peerID := room.AddPeer(peer)

	log.Printf("Peer %d joined room %s", peerID, roomCode)

	// Tell the new peer their ID and existing peers
	// Format: [MsgTypeRoomJoined][peerID:4][numPeers:4][peerID1:4][peerID2:4]...
	response := make([]byte, 1+4+4+len(existingPeerIDs)*4)
	response[0] = MsgTypeRoomJoined
	binary.LittleEndian.PutUint32(response[1:5], peerID)
	binary.LittleEndian.PutUint32(response[5:9], uint32(len(existingPeerIDs)))
	for i, id := range existingPeerIDs {
		binary.LittleEndian.PutUint32(response[9+i*4:13+i*4], id)
	}
	peer.Send(response)

	// Tell existing peers about the new peer
	// Format: [MsgTypePeerJoined][peerID:4]
	announcement := make([]byte, 5)
	announcement[0] = MsgTypePeerJoined
	binary.LittleEndian.PutUint32(announcement[1:5], peerID)
	room.Broadcast(announcement, peerID)
}

func (s *Server) handleData(peer *Peer, payload []byte) {
	if peer.Room == nil || len(payload) < 4 {
		return
	}

	// Payload format: [targetPeerID:4][data...]
	targetID := binary.LittleEndian.Uint32(payload[0:4])
	gameData := payload[4:]

	// Wrap with sender info for recipients
	// Format: [MsgTypeData][senderPeerID:4][data...]
	wrapped := make([]byte, 1+4+len(gameData))
	wrapped[0] = MsgTypeData
	binary.LittleEndian.PutUint32(wrapped[1:5], peer.ID)
	copy(wrapped[5:], gameData)

	if targetID == PeerIDBroadcast {
		peer.Room.Broadcast(wrapped, peer.ID)
	} else {
		peer.Room.SendTo(targetID, wrapped)
	}
}

// closeRoom closes an entire room and disconnects all remaining peers
// This is called when the host (peer ID 1) disconnects
func (s *Server) closeRoom(room *Room, hostID uint32) {
	roomCode := room.Code

	// Get snapshot of all peers to notify excluding the host who already disconnected
	room.mu.RLock()
	peersToClose := make([]*Peer, 0, len(room.Peers))
	for id, peer := range room.Peers {
		if id != hostID {
			peersToClose = append(peersToClose, peer)
		}
	}
	room.mu.RUnlock()

	// Send ROOM_CLOSED notification to all remaining peers
	// Format: [MsgTypeRoomClosed][hostPeerID:4]
	msg := make([]byte, 5)
	msg[0] = MsgTypeRoomClosed
	binary.LittleEndian.PutUint32(msg[1:5], hostID)

	for _, peer := range peersToClose {
		peer.Send(msg) // Best effort, ignore errors
	}

	// Small delay to ensure message is sent before closing connections
	time.Sleep(50 * time.Millisecond)

	for _, peer := range peersToClose {
		peer.Conn.Close()
	}

	room.mu.Lock()
	for id := range room.Peers {
		delete(room.Peers, id)
	}
	room.mu.Unlock()

	s.roomsMu.Lock()
	delete(s.rooms, roomCode)
	s.roomsMu.Unlock()

	log.Printf("Closed room %s due to host (peer %d) disconnect, removed %d peers",
		roomCode, hostID, len(peersToClose))
}

func (s *Server) cleanupPeer(peer *Peer) {
	peer.Conn.Close()

	if peer.Room != nil {
		roomCode := peer.Room.Code

		// Special handling: if host disconnects, close the entire room
		if peer.ID == PeerIDServer {
			log.Printf("Host (peer %d) disconnecting from room %s, closing room", peer.ID, roomCode)
			s.closeRoom(peer.Room, peer.ID)
			return
		}

		// Normal peer disconnect: notify others and cleanup if room becomes empty
		peer.Room.RemovePeer(peer.ID)

		// Notify remaining peers
		msg := make([]byte, 5)
		msg[0] = MsgTypePeerLeft
		binary.LittleEndian.PutUint32(msg[1:5], peer.ID)
		peer.Room.Broadcast(msg, peer.ID)

		log.Printf("Peer %d left room %s", peer.ID, roomCode)

		s.CleanupRoom(roomCode)
	}
}

func main() {
	server := NewServer()

	http.HandleFunc("/ws", server.HandleConnection)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok"))
	})

	addr := ":56564"
	log.Printf("Relay server starting on %s", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
