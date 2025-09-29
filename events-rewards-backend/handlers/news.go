package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/Hritikpandey-ops/events-rewards-backend/models"
	"github.com/Hritikpandey-ops/events-rewards-backend/utils"

	"github.com/gorilla/mux"
	"gorm.io/gorm"
)

type NewsHandler struct {
	db *gorm.DB
}

func NewNewsHandler(db *gorm.DB) *NewsHandler {
	return &NewsHandler{db: db}
}

// GetNews - Get all published news with optional filtering
func (h *NewsHandler) GetNews(w http.ResponseWriter, r *http.Request) {
	query := h.db.Model(&models.News{}).Where("is_published = ?", true)

	// Apply filters from query parameters
	if category := r.URL.Query().Get("category"); category != "" {
		query = query.Where("category = ?", category)
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
		if parsedLimit, err := strconv.Atoi(l); err == nil && parsedLimit > 0 && parsedLimit <= 50 {
			limit = parsedLimit
		}
	}

	offset := (page - 1) * limit

	var news []models.News
	var totalCount int64

	// Get total count
	query.Count(&totalCount)

	// Get news with pagination
	result := query.
		Order("publish_date DESC").
		Offset(offset).
		Limit(limit).
		Find(&news)

	if result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch news")
		return
	}

	// Calculate pagination info
	totalPages := int((totalCount + int64(limit) - 1) / int64(limit))
	hasNext := page < totalPages
	hasPrev := page > 1

	utils.SuccessResponse(w, map[string]interface{}{
		"news": news,
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

// GetNewsArticle - Get a specific news article by ID
func (h *NewsHandler) GetNewsArticle(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	newsID := vars["id"]

	if newsID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "News ID is required")
		return
	}

	var news models.News
	result := h.db.Where("id = ? AND is_published = ?", newsID, true).First(&news)

	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			utils.ErrorResponse(w, http.StatusNotFound, "News article not found")
		} else {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch news article")
		}
		return
	}

	utils.SuccessResponse(w, news)
}

// CreateNews - Create a new news article (admin only - for now, any authenticated user)
func (h *NewsHandler) CreateNews(w http.ResponseWriter, r *http.Request) {
	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	var req models.CreateNewsRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate required fields
	if req.Title == "" || req.Content == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Title and content are required")
		return
	}

	news := models.News{
		Title:       req.Title,
		Content:     req.Content,
		Summary:     &req.Summary,
		ImageURL:    &req.ImageURL,
		Category:    &req.Category,
		IsPublished: req.IsPublished,
		AuthorID:    userID,
	}

	// Set publish date if being published
	if req.IsPublished {
		now := time.Now()
		news.PublishDate = &now
	}

	if result := h.db.Create(&news); result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to create news article")
		return
	}

	utils.SuccessResponse(w, news)
}

// UpdateNews - Update an existing news article
func (h *NewsHandler) UpdateNews(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	newsID := vars["id"]

	if newsID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "News ID is required")
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	var req models.UpdateNewsRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	var news models.News
	result := h.db.Where("id = ? AND author_id = ?", newsID, userID).First(&news)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			utils.ErrorResponse(w, http.StatusNotFound, "News article not found or you don't have permission to edit it")
		} else {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch news article")
		}
		return
	}

	// Update fields if provided
	if req.Title != nil {
		news.Title = *req.Title
	}
	if req.Content != nil {
		news.Content = *req.Content
	}
	if req.Summary != nil {
		news.Summary = req.Summary
	}
	if req.ImageURL != nil {
		news.ImageURL = req.ImageURL
	}
	if req.Category != nil {
		news.Category = req.Category
	}
	if req.IsPublished != nil {
		news.IsPublished = *req.IsPublished

		// Set publish date if being published for the first time
		if *req.IsPublished && news.PublishDate == nil {
			now := time.Now()
			news.PublishDate = &now
		}
	}

	if result := h.db.Save(&news); result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to update news article")
		return
	}

	utils.SuccessResponse(w, news)
}

// DeleteNews - Delete a news article
func (h *NewsHandler) DeleteNews(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	newsID := vars["id"]

	if newsID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "News ID is required")
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	var news models.News
	result := h.db.Where("id = ? AND author_id = ?", newsID, userID).First(&news)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			utils.ErrorResponse(w, http.StatusNotFound, "News article not found or you don't have permission to delete it")
		} else {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch news article")
		}
		return
	}

	if result := h.db.Delete(&news); result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to delete news article")
		return
	}

	utils.MessageResponse(w, "News article deleted successfully")
}

// GetMyNews - Get news articles created by the authenticated user
func (h *NewsHandler) GetMyNews(w http.ResponseWriter, r *http.Request) {
	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	query := h.db.Model(&models.News{}).Where("author_id = ?", userID)

	// Apply filters from query parameters
	if category := r.URL.Query().Get("category"); category != "" {
		query = query.Where("category = ?", category)
	}

	if isPublished := r.URL.Query().Get("is_published"); isPublished != "" {
		if published, err := strconv.ParseBool(isPublished); err == nil {
			query = query.Where("is_published = ?", published)
		}
	}

	// Pagination
	page := 1
	limit := 20
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

	var news []models.News
	var totalCount int64

	// Get total count
	query.Count(&totalCount)

	// Get news with pagination
	result := query.
		Order("created_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&news)

	if result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch your news articles")
		return
	}

	// Calculate pagination info
	totalPages := int((totalCount + int64(limit) - 1) / int64(limit))
	hasNext := page < totalPages
	hasPrev := page > 1

	utils.SuccessResponse(w, map[string]interface{}{
		"news": news,
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

// GetCategories - Get all news categories
func (h *NewsHandler) GetCategories(w http.ResponseWriter, r *http.Request) {
	var categories []string

	result := h.db.Model(&models.News{}).
		Select("DISTINCT category").
		Where("category IS NOT NULL AND category != '' AND is_published = ?", true).
		Pluck("category", &categories)

	if result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch categories")
		return
	}

	utils.SuccessResponse(w, categories)
}

// GetLatestNews - Get latest news articles (homepage feed)
func (h *NewsHandler) GetLatestNews(w http.ResponseWriter, r *http.Request) {
	limit := 5
	if l := r.URL.Query().Get("limit"); l != "" {
		if parsedLimit, err := strconv.Atoi(l); err == nil && parsedLimit > 0 && parsedLimit <= 20 {
			limit = parsedLimit
		}
	}

	var news []models.News
	result := h.db.Where("is_published = ?", true).
		Order("publish_date DESC").
		Limit(limit).
		Find(&news)

	if result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch latest news")
		return
	}

	utils.SuccessResponse(w, news)
}

func (h *NewsHandler) TogglePublishStatus(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	newsID := vars["id"]
	if newsID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "News ID is required")
		return
	}

	// Get user ID from context
	userID, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	var news models.News
	result := h.db.Where("id = ? AND author_id = ?", newsID, userID).First(&news)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			utils.ErrorResponse(w, http.StatusNotFound, "News article not found or you don't have permission to edit it")
		} else {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch news article")
		}
		return
	}

	// Toggle publish status
	news.IsPublished = !news.IsPublished

	// Set publish date if being published for the first time
	if news.IsPublished && news.PublishDate == nil {
		now := time.Now()
		news.PublishDate = &now
	}

	if result := h.db.Save(&news); result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to update news article")
		return
	}

	utils.SuccessResponse(w, news)
}

// BookmarkNews - Bookmark a news article (placeholder)
func (h *NewsHandler) BookmarkNews(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	newsID := vars["id"]
	if newsID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "News ID is required")
		return
	}

	// Get user ID from context
	//userID, ok := r.Context().Value("user_id").(string)
	// if !ok {
	// 	utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
	// 	return
	// }

	// For now, just return success (implement actual bookmarking logic later)
	utils.MessageResponse(w, "News article bookmarked successfully")
}
