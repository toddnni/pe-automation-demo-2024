package db

import (
	"database/sql"
	"fmt"
	_ "github.com/glebarez/go-sqlite" // SQLite driver
	_ "github.com/lib/pq"             // PostgreSQL driver
	"log"
	"os"
)

var db *sql.DB

// DB defines an interface for database operations
type DB interface {
	StoreMessage(message string) error
	GetMessages() ([]string, error)
	Close() error
}

// InitDB initializes the database connection (PostgreSQL or SQLite)
func InitDB() (DB, error) {
	dbType := os.Getenv("DB_TYPE") // either "postgres" or "sqlite"

	switch dbType {
	case "postgres":
		return initPostgresDB()
	case "sqlite":
		return initSQLiteDB()
	default:
		return nil, fmt.Errorf("unsupported DB_TYPE: %s", dbType)
	}
}

// initializes the PostgreSQL database connection
func initPostgresDB() (DB, error) {
	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbUser := os.Getenv("DB_USER")
	dbName := os.Getenv("DB_NAME")
	dbSSLMode := os.Getenv("DB_SSLMODE")

	// Build PostgreSQL connection string
	dsn := fmt.Sprintf("host=%s port=%s user=%s dbname=%s sslmode=%s", dbHost, dbPort, dbUser, dbName, dbSSLMode)

	// Open connection to the database
	var err error
	db, err = sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("could not connect to the database: %w", err)
	}

	// Ping to verify the connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("could not ping the database: %w", err)
	}

	log.Println("Connected to the database")
	return &postgresDB{}, nil
}

// initSQLiteDB initializes SQLite connection
func initSQLiteDB() (DB, error) {
	dbPath := os.Getenv("DB_PATH") // Local SQLite file path

	// Open connection to SQLite
	var err error
	db, err = sql.Open("sqlite", dbPath)
	if err != nil {
		return nil, fmt.Errorf("could not connect to SQLite: %w", err)
	}

	// Create the table if not exists
	createTableQuery := `
	CREATE TABLE IF NOT EXISTS messages (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		content TEXT NOT NULL
	);`
	_, err = db.Exec(createTableQuery)
	if err != nil {
		return nil, fmt.Errorf("could not create table: %w", err)
	}
	log.Println("Initialized sqlite database")

	return &sqliteDB{}, nil
}

// postgresDB implements the DB interface for PostgreSQL
type postgresDB struct{}

func (p *postgresDB) StoreMessage(message string) error {
	query := "INSERT INTO messages (content) VALUES ($1)"
	_, err := db.Exec(query, message)
	return err
}

func (p *postgresDB) Close() error {
	return db.Close()
}

// sqliteDB implements the DB interface for SQLite
type sqliteDB struct{}

func (s *sqliteDB) StoreMessage(message string) error {
	query := "INSERT INTO messages (content) VALUES (?)"
	_, err := db.Exec(query, message)
	return err
}

func (s *sqliteDB) Close() error {
	return db.Close()
}

// Shared

func (s *sqliteDB) GetMessages() ([]string, error) {
	return SQLGetMessages()
}

func (s *postgresDB) GetMessages() ([]string, error) {
	return SQLGetMessages()
}

func SQLGetMessages() ([]string, error) {
	rows, err := db.Query("SELECT content FROM messages")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var messages []string
	for rows.Next() {
		var content string
		if err := rows.Scan(&content); err != nil {
			return nil, err
		}
		messages = append(messages, content)
	}

	return messages, nil
}
