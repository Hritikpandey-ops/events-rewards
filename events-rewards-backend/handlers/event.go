package handlers

import (
	"encoding/json"
	"fmt"
	"math"
	"net/http"
	"strconv"
	"time"

	"github.com/Hritikpandey-ops/events-rewards-backend/models"
	"github.com/Hritikpandey-ops/events-rewards-backend/utils"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"gorm.io/gorm"
)

type EventHandler struct {
	db *gorm.DB
}

func NewEventHandler(db *gorm.DB) *EventHandler {
	return &EventHandler{db: db}
}

// GetEvents - Get all events with optional filtering
func (h *EventHandler) GetEvents(w http.ResponseWriter, r *http.Request) {
	query := h.db.Model(&models.Event{}).Where("is_active = ?", true)

	// Apply filters from query parameters
	if category := r.URL.Query().Get("category"); category != "" {
		query = query.Where("category = ?", category)
	}

	if location := r.URL.Query().Get("location"); location != "" {
		query = query.Where("location ILIKE ?", "%"+location+"%")
	}

	if dateFrom := r.URL.Query().Get("date_from"); dateFrom != "" {
		if parsedDate, err := time.Parse("2006-01-02", dateFrom); err == nil {
			query = query.Where("event_date >= ?", parsedDate)
		}
	}

	if dateTo := r.URL.Query().Get("date_to"); dateTo != "" {
		if parsedDate, err := time.Parse("2006-01-02", dateTo); err == nil {
			query = query.Where("event_date <= ?", parsedDate)
		}
	}

	// Pagination
	page := 1
	limit := 10
	if p := r.URL.Query().Get("page"); p != "" {
		if parsedPage, err := strconv.Atoi(p); err == nil && parsedPage > 0 {
			page = parsedPage
		}
	}
	if l := r.URL.Query().Get("limit"); l != "" {
		if parsedLimit, err := strconv.Atoi(l); err == nil && parsedLimit > 0 && parsedLimit <= 100 {
			limit = parsedLimit
		}
	}

	offset := (page - 1) * limit

	var events []models.Event
	var totalCount int64

	// Get total count
	query.Count(&totalCount)

	// Get events with pagination
	result := query.
		Preload("Creator").
		Preload("Registrations").
		Order("event_date ASC").
		Offset(offset).
		Limit(limit).
		Find(&events)

	if result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch events")
		return
	}

	// Calculate pagination info
	totalPages := int((totalCount + int64(limit) - 1) / int64(limit))
	hasNext := page < totalPages
	hasPrev := page > 1

	utils.SuccessResponse(w, map[string]interface{}{
		"events": events,
		"pagination": map[string]interface{}{
			"current_page": page,
			"total_pages":  totalPages,
			"total_count":  totalCount,
			"has_next":     hasNext,
			"has_prev":     hasPrev,
			"limit":        limit,
		},
	})
}

// GetEvent - Get a specific event by ID
func (h *EventHandler) GetEvent(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	eventID := vars["id"]

	if eventID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Event ID is required")
		return
	}

	var event models.Event
	result := h.db.
		Preload("Creator").
		Preload("Registrations").
		Preload("Registrations.User").
		Where("id = ? AND is_active = ?", eventID, true).
		First(&event)

	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			utils.ErrorResponse(w, http.StatusNotFound, "Event not found")
		} else {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch event")
		}
		return
	}

	utils.SuccessResponse(w, event)
}

// GetUserEvents - Get events created by the current user
func (h *EventHandler) GetUserEvents(w http.ResponseWriter, r *http.Request) {
	// Get current user ID from context
	userID, ok := r.Context().Value("user_id").(string)
	if !ok || userID == "" {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User authentication required")
		return
	}

	// Parse query parameters
	query := r.URL.Query()
	page, _ := strconv.Atoi(query.Get("page"))
	limit, _ := strconv.Atoi(query.Get("limit"))

	// Set defaults
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	offset := (page - 1) * limit

	var events []models.Event
	var totalCount int64

	// Get total count
	countResult := h.db.Model(&models.Event{}).
		Where("created_by = ? AND is_active = ?", userID, true).
		Count(&totalCount)

	if countResult.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to count events")
		return
	}

	// Fetch events with pagination
	result := h.db.
		Preload("Creator").
		Preload("Registrations").
		Preload("Registrations.User").
		Where("created_by = ? AND is_active = ?", userID, true).
		Order("event_date ASC").
		Offset(offset).
		Limit(limit).
		Find(&events)

	if result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch user events")
		return
	}

	// Calculate pagination info
	totalPages := int(math.Ceil(float64(totalCount) / float64(limit)))
	hasNext := page < totalPages
	hasPrev := page > 1

	response := map[string]interface{}{
		"events": events,
		"pagination": map[string]interface{}{
			"current_page": page,
			"has_next":     hasNext,
			"has_prev":     hasPrev,
			"limit":        limit,
			"total_count":  totalCount,
			"total_pages":  totalPages,
		},
	}

	utils.SuccessResponse(w, response)
}

// CreateEvent - Create a new event
func (h *EventHandler) CreateEvent(w http.ResponseWriter, r *http.Request) {
	// Get user ID from context
	userIDStr, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid user ID")
		return
	}

	var req models.CreateEventRequest

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		fmt.Printf("DEBUG: JSON decode error: %v\n", err)
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	fmt.Printf("DEBUG: Parsed request: %+v\n", req)

	// Parse the date string manually using RFC3339 format
	eventDate, err := time.Parse(time.RFC3339, req.EventDateStr)
	if err != nil {
		fmt.Printf("DEBUG: Date parsing error: %v\n", err)
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid date format. Use ISO8601/RFC3339 format")
		return
	}

	fmt.Printf("DEBUG: Parsed EventDate: %v\n", eventDate)

	// Validate required fields
	if req.Title == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Title is required")
		return
	}

	if eventDate.IsZero() {
		utils.ErrorResponse(w, http.StatusBadRequest, "Event date is required")
		return
	}

	// Validate event date is not in the past
	if eventDate.Before(time.Now()) {
		utils.ErrorResponse(w, http.StatusBadRequest, "Event date cannot be in the past")
		return
	}

	// Set default values for optional fields
	maxParticipants := 50
	if req.MaxParticipants != nil {
		maxParticipants = *req.MaxParticipants
	}

	bannerImage := ""
	if req.BannerImage != nil {
		bannerImage = *req.BannerImage
	}

	// Create event with parsed date
	event := models.Event{
		Title:           req.Title,
		Description:     &req.Description,
		EventDate:       eventDate,
		Location:        &req.Location,
		MaxParticipants: &maxParticipants,
		BannerImage:     &bannerImage,
		Category:        &req.Category,
		CreatedBy:       &userID,
		IsActive:        true,
	}

	fmt.Printf("DEBUG: Creating event: %+v\n", event)

	if result := h.db.Create(&event); result.Error != nil {
		fmt.Printf("DEBUG: Database error: %v\n", result.Error)
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to create event")
		return
	}

	// Load the created event with relationships
	h.db.Preload("Creator").First(&event, event.ID)

	fmt.Printf("DEBUG: Event created successfully: %+v\n", event)
	utils.SuccessResponse(w, event)
}

// UpdateEvent - Update an existing event
func (h *EventHandler) UpdateEvent(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	eventID := vars["id"]

	if eventID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Event ID is required")
		return
	}

	// Get user ID from context
	userIDStr, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	var req models.UpdateEventRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	var event models.Event
	result := h.db.Where("id = ?", eventID).First(&event)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			utils.ErrorResponse(w, http.StatusNotFound, "Event not found")
		} else {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch event")
		}
		return
	}

	// Check if user is the creator of the event
	if event.CreatedBy == nil || event.CreatedBy.String() != userIDStr {
		utils.ErrorResponse(w, http.StatusForbidden, "You can only update your own events")
		return
	}

	// Update fields if provided
	if req.Title != nil {
		event.Title = *req.Title
	}
	if req.Description != nil {
		event.Description = req.Description
	}
	if req.EventDate != nil {
		if req.EventDate.Before(time.Now()) {
			utils.ErrorResponse(w, http.StatusBadRequest, "Event date cannot be in the past")
			return
		}
		event.EventDate = *req.EventDate
	}
	if req.Location != nil {
		event.Location = req.Location
	}
	if req.MaxParticipants != nil {
		event.MaxParticipants = req.MaxParticipants
	}
	if req.BannerImage != nil {
		event.BannerImage = req.BannerImage
	}
	if req.Category != nil {
		event.Category = req.Category
	}
	if req.IsActive != nil {
		event.IsActive = *req.IsActive
	}

	if result := h.db.Save(&event); result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to update event")
		return
	}

	utils.SuccessResponse(w, event)
}

// DeleteEvent - Delete an event (soft delete)
func (h *EventHandler) DeleteEvent(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	eventID := vars["id"]
	if eventID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Event ID is required")
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(string)
	if !ok || userID == "" {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User authentication required")
		return
	}

	var event models.Event
	result := h.db.Where("id = ?", eventID).First(&event)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			utils.ErrorResponse(w, http.StatusNotFound, "Event not found")
		} else {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch event")
		}
		return
	}

	// Check if user is the creator of the event
	if event.CreatedBy.String() != userID {
		utils.ErrorResponse(w, http.StatusForbidden, "You can only delete your own events")
		return
	}

	// Soft delete the event (sets deleted_at timestamp)
	if result := h.db.Delete(&event); result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to delete event")
		return
	}

	utils.MessageResponse(w, "Event deleted successfully")
}

// RegisterForEvent - Register a user for an event
func (h *EventHandler) RegisterForEvent(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	eventID := vars["id"]

	if eventID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Event ID is required")
		return
	}

	// Get user ID from context
	userIDStr, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid user ID")
		return
	}

	// Check if event exists and is active
	var event models.Event
	result := h.db.Where("id = ? AND is_active = ?", eventID, true).First(&event)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			utils.ErrorResponse(w, http.StatusNotFound, "Event not found")
		} else {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch event")
		}
		return
	}

	// Check if event is not in the past
	if event.EventDate.Before(time.Now()) {
		utils.ErrorResponse(w, http.StatusBadRequest, "Cannot register for past events")
		return
	}

	// Check if user is already registered
	var existingRegistration models.EventRegistration
	if h.db.Where("user_id = ? AND event_id = ?", userID, eventID).First(&existingRegistration).Error == nil {
		utils.ErrorResponse(w, http.StatusConflict, "Already registered for this event")
		return
	}

	// Check if event has reached maximum capacity
	if event.MaxParticipants != nil && event.CurrentParticipants >= *event.MaxParticipants {
		utils.ErrorResponse(w, http.StatusBadRequest, "Event has reached maximum capacity")
		return
	}

	// Create registration
	registration := models.EventRegistration{
		UserID:  userID,
		EventID: uuid.MustParse(eventID),
		Status:  "registered",
	}

	tx := h.db.Begin()

	if result := tx.Create(&registration); result.Error != nil {
		tx.Rollback()
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to register for event")
		return
	}

	// Update current participants count
	if result := tx.Model(&event).Update("current_participants", gorm.Expr("current_participants + 1")); result.Error != nil {
		tx.Rollback()
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to update participant count")
		return
	}

	tx.Commit()

	// Load registration with relationships
	h.db.Preload("User").Preload("Event").First(&registration, registration.ID)

	utils.SuccessResponse(w, map[string]interface{}{
		"message":      "Successfully registered for event",
		"registration": registration,
	})
}

// UnregisterFromEvent - Unregister a user from an event
func (h *EventHandler) UnregisterFromEvent(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	eventID := vars["id"]

	if eventID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Event ID is required")
		return
	}

	// Get user ID from context
	userIDStr, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid user ID")
		return
	}

	// Find the registration
	var registration models.EventRegistration
	result := h.db.Where("user_id = ? AND event_id = ?", userID, eventID).First(&registration)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			utils.ErrorResponse(w, http.StatusNotFound, "Registration not found")
		} else {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch registration")
		}
		return
	}

	tx := h.db.Begin()

	// Delete registration
	if result := tx.Delete(&registration); result.Error != nil {
		tx.Rollback()
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to unregister from event")
		return
	}

	// Update current participants count
	if result := tx.Model(&models.Event{}).Where("id = ?", eventID).Update("current_participants", gorm.Expr("current_participants - 1")); result.Error != nil {
		tx.Rollback()
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to update participant count")
		return
	}

	tx.Commit()

	utils.MessageResponse(w, "Successfully unregistered from event")
}

// GetUserRegistrations - Get all events a user is registered for
func (h *EventHandler) GetUserRegistrations(w http.ResponseWriter, r *http.Request) {
	// Get user ID from context
	userIDStr, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	var registrations []models.EventRegistration
	result := h.db.
		Preload("Event").
		Preload("Event.Creator").
		Where("user_id = ?", userIDStr).
		Order("registration_date DESC").
		Find(&registrations)

	if result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch registrations")
		return
	}

	utils.SuccessResponse(w, registrations)
}
