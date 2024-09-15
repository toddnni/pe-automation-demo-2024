package main

import (
	"go-k8s-app/internal/db"
	"go-k8s-app/internal/handlers"
	"log"
	"net/http"
)

func main() {
	// Initialize database connection based on DB_TYPE
	database, err := db.InitDB()
	if err != nil {
		log.Fatalf("Could not initialize database: %v", err)
	}
	defer database.Close()

	// Serve static files (HTML)
	http.Handle("/", http.FileServer(http.Dir("./web")))

	// API endpoint for submitting messages
	http.HandleFunc("/submit", func(w http.ResponseWriter, r *http.Request) {
		handlers.SubmitMessageWithDB(database, w, r)
	})

	// API endpoint for fetching messages
	http.HandleFunc("/messages", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetMessagesWithDB(database, w, r)
	})

	// Start server
	log.Println("Starting server on :8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
