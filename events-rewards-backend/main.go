package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/Hritikpandey-ops/events-rewards-backend/config"
	"github.com/Hritikpandey-ops/events-rewards-backend/handlers"
	"github.com/Hritikpandey-ops/events-rewards-backend/middleware"
	"github.com/Hritikpandey-ops/events-rewards-backend/models"
	"github.com/Hritikpandey-ops/events-rewards-backend/services"
	"github.com/gorilla/mux"
	"gorm.io/gorm"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Initialize database
	db := config.InitDB(cfg.DatabaseURL)

	// Smart migration: Check environment variable for migration strategy
	migrationMode := os.Getenv("MIGRATION_MODE")
	if migrationMode == "" {
		migrationMode = "auto" // Default to auto migration
	}

	switch migrationMode {
	case "skip":
		log.Println("Skipping database migration (MIGRATION_MODE=skip)")
	case "safe":
		log.Println("Running safe migration with error handling...")
		performSafeMigration(db)
	case "auto":
		log.Println("Running automatic migration...")
		performAutoMigration(db)
	default:
		log.Printf("Unknown migration mode '%s', defaulting to auto", migrationMode)
		performAutoMigration(db)
	}

	// Initialize MinIO service
	minioService, err := services.NewMinIOService(services.MinIOConfig{
		Endpoint:   cfg.MinIO.Endpoint,
		AccessKey:  cfg.MinIO.AccessKey,
		SecretKey:  cfg.MinIO.SecretKey,
		BucketName: cfg.MinIO.BucketName,
		UseSSL:     cfg.MinIO.UseSSL,
	})
	if err != nil {
		log.Fatal("Failed to initialize MinIO service:", err)
	}

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(db, minioService)
	eventHandler := handlers.NewEventHandler(db)
	newsHandler := handlers.NewNewsHandler(db)
	uiConfigHandler := handlers.NewUIConfigHandler(db)
	luckyDrawHandler := handlers.NewLuckyDrawHandler(db)
	userHandler := handlers.NewUserHandler(db)

	// Setup router
	r := mux.NewRouter()

	// Apply CORS middleware
	r.Use(middleware.CORSMiddleware)

	// Global OPTIONS handler for all routes (catches any missed OPTIONS requests)
	r.Methods("OPTIONS").HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// CORS headers are already set by the middleware
		w.WriteHeader(http.StatusOK)
	})

	// API routes
	api := r.PathPrefix("/api/v1").Subrouter()

	// Public routes (no authentication required) - NOW WITH OPTIONS SUPPORT
	api.HandleFunc("/auth/register", authHandler.Register).Methods("POST", "OPTIONS")
	api.HandleFunc("/auth/login", authHandler.Login).Methods("POST", "OPTIONS")

	// Public news routes
	api.HandleFunc("/news", newsHandler.GetNews).Methods("GET", "OPTIONS")
	api.HandleFunc("/news/{id}", newsHandler.GetNewsArticle).Methods("GET", "OPTIONS")

	// Public events routes
	api.HandleFunc("/events", eventHandler.GetEvents).Methods("GET", "OPTIONS")
	api.HandleFunc("/events/{id}", eventHandler.GetEvent).Methods("GET", "OPTIONS")

	// Public UI config routes
	api.HandleFunc("/config/ui", uiConfigHandler.GetConfig).Methods("GET", "OPTIONS")

	// Health check endpoint
	api.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{
			"status":  "ok",
			"message": "Server is running",
		})
	}).Methods("GET", "OPTIONS")

	// Protected routes (require authentication)
	protected := api.NewRoute().Subrouter()
	protected.Use(middleware.AuthMiddleware)

	// Auth routes (protected) - WITH OPTIONS SUPPORT
	protected.HandleFunc("/auth/verify-identity", authHandler.VerifyIdentity).Methods("POST", "OPTIONS")
	protected.HandleFunc("/auth/upload-selfie", authHandler.UploadSelfie).Methods("POST", "OPTIONS")
	protected.HandleFunc("/auth/upload-voice", authHandler.UploadVoice).Methods("POST", "OPTIONS")
	protected.HandleFunc("/auth/profile", authHandler.GetUserProfile).Methods("GET", "OPTIONS")

	//User Routes
	protected.HandleFunc("/user/profile", authHandler.GetUserProfile).Methods("GET", "OPTIONS")
	protected.HandleFunc("/user/upload-selfie", authHandler.UploadSelfie).Methods("POST", "OPTIONS")
	protected.HandleFunc("/user/upload-voice", authHandler.UploadVoice).Methods("POST", "OPTIONS")
	protected.HandleFunc("/user/events", eventHandler.GetUserEvents).Methods("GET", "OPTIONS")

	// Event routes (protected) - WITH OPTIONS SUPPORT
	protected.HandleFunc("/events", eventHandler.CreateEvent).Methods("POST", "OPTIONS")
	protected.HandleFunc("/events", eventHandler.GetEvents).Methods("GET", "OPTIONS")
	protected.HandleFunc("/events/{id}", eventHandler.UpdateEvent).Methods("PUT", "OPTIONS")
	protected.HandleFunc("/events/{id}", eventHandler.DeleteEvent).Methods("DELETE", "OPTIONS")
	protected.HandleFunc("/events/{id}/register", eventHandler.RegisterForEvent).Methods("POST", "OPTIONS")
	protected.HandleFunc("/events/{id}/unregister", eventHandler.UnregisterFromEvent).Methods("DELETE", "OPTIONS")
	protected.HandleFunc("/events/my-events", eventHandler.GetUserRegistrations).Methods("GET", "OPTIONS")

	// News routes (protected - for admin/content management) - WITH OPTIONS SUPPORT
	protected.HandleFunc("/news", newsHandler.CreateNews).Methods("POST", "OPTIONS")
	protected.HandleFunc("/news/{id}", newsHandler.UpdateNews).Methods("PUT", "OPTIONS")
	protected.HandleFunc("/news/{id}", newsHandler.DeleteNews).Methods("DELETE", "OPTIONS")

	// UI Config routes (protected) - WITH OPTIONS SUPPORT
	protected.HandleFunc("/ui-config", uiConfigHandler.CreateConfig).Methods("POST", "OPTIONS")
	protected.HandleFunc("/ui-config/{id}", uiConfigHandler.UpdateConfig).Methods("PUT", "OPTIONS")
	protected.HandleFunc("/ui-config/{id}", uiConfigHandler.DeleteConfig).Methods("DELETE", "OPTIONS")

	// Lucky Draw routes (protected) - WITH OPTIONS SUPPORT
	protected.HandleFunc("/lucky-draw/spin", luckyDrawHandler.Spin).Methods("POST", "OPTIONS")
	protected.HandleFunc("/lucky-draw/remaining-spins", luckyDrawHandler.GetRemainingSpins).Methods("GET", "OPTIONS")
	protected.HandleFunc("/lucky-draw/claim", luckyDrawHandler.ClaimReward).Methods("POST", "OPTIONS")

	// User reward routes for retrieving rewards and stats - WITH OPTIONS SUPPORT
	protected.HandleFunc("/user/rewards", userHandler.GetUserRewards).Methods("GET", "OPTIONS")
	protected.HandleFunc("/user/stats", userHandler.GetUserStats).Methods("GET", "OPTIONS")

	// Start server
	log.Printf("Server starting on port %s", cfg.Port)
	log.Printf("MinIO Console available at: http://localhost:9001")
	log.Printf("pgAdmin available at: http://localhost:5051")
	log.Fatal(http.ListenAndServe(":"+cfg.Port, r))
}

// performAutoMigration runs standard GORM auto migration
func performAutoMigration(db *gorm.DB) {
	err := db.AutoMigrate(
		&models.User{},
		&models.Event{},
		&models.EventRegistration{},
		&models.News{},
		&models.UIConfig{},
		&models.Reward{},
		&models.UserReward{},
		&models.SpinAttempt{},
	)

	if err != nil {
		log.Fatal("Failed to migrate database:", err)
	}

	log.Println("Database migration completed successfully")
}

// performSafeMigration runs migration with error handling for production
func performSafeMigration(db *gorm.DB) {
	models := []interface{}{
		&models.User{},
		&models.Event{},
		&models.EventRegistration{},
		&models.News{},
		&models.UIConfig{},
		&models.Reward{},
		&models.UserReward{},
		&models.SpinAttempt{},
	}

	for _, model := range models {
		if err := db.AutoMigrate(model); err != nil {
			log.Printf("Migration warning for model %T: %v", model, err)
			log.Println("  Continuing with existing schema...")
		} else {
			log.Printf("Successfully migrated model: %T", model)
		}
	}

	log.Println("Safe migration completed")
}
