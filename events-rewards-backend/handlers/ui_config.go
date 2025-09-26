package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/Hritikpandey-ops/events-rewards-backend/models"
	"github.com/Hritikpandey-ops/events-rewards-backend/utils"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
	"gorm.io/gorm"
)

type UIConfigHandler struct {
	db *gorm.DB
}

func NewUIConfigHandler(db *gorm.DB) *UIConfigHandler {
	return &UIConfigHandler{db: db}
}

// GetConfig - Get UI configuration for a user or default config
func (h *UIConfigHandler) GetConfig(w http.ResponseWriter, r *http.Request) {
	configType := r.URL.Query().Get("type")
	if configType == "" {
		configType = "default_home"
	}

	// Get user ID from context (optional for default configs)
	userIDStr, _ := r.Context().Value("user_id").(string)

	var config models.UIConfig
	var result *gorm.DB

	// First try to get user-specific config
	if userIDStr != "" {
		userID, err := uuid.Parse(userIDStr)
		if err == nil {
			result = h.db.Where("user_id = ? AND config_type = ? AND is_active = ?", userID, configType, true).First(&config)
		}
	}

	// If no user-specific config found, get default config
	if result == nil || result.Error == gorm.ErrRecordNotFound {
		result = h.db.Where("user_id IS NULL AND config_type = ? AND is_active = ?", configType, true).First(&config)
	}

	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			utils.ErrorResponse(w, http.StatusNotFound, "Configuration not found")
		} else {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch configuration")
		}
		return
	}

	utils.SuccessResponse(w, config)
}

// GetAllConfigs - Get all UI configurations for a user
func (h *UIConfigHandler) GetAllConfigs(w http.ResponseWriter, r *http.Request) {
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

	var configs []models.UIConfig
	result := h.db.Where("(user_id = ? OR user_id IS NULL) AND is_active = ?", userID, true).Order("user_id DESC, config_type").Find(&configs)

	if result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch configurations")
		return
	}

	// Group configs by type, prioritizing user-specific configs
	configMap := make(map[string]models.UIConfig)
	for _, config := range configs {
		if _, exists := configMap[config.ConfigType]; !exists || config.UserID != nil {
			configMap[config.ConfigType] = config
		}
	}

	// Convert map back to slice
	var finalConfigs []models.UIConfig
	for _, config := range configMap {
		finalConfigs = append(finalConfigs, config)
	}

	utils.SuccessResponse(w, finalConfigs)
}

// CreateConfig - Create a new UI configuration
func (h *UIConfigHandler) CreateConfig(w http.ResponseWriter, r *http.Request) {
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

	var req models.CreateUIConfigRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate required fields
	if req.ConfigType == "" || req.ConfigData == nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Config type and data are required")
		return
	}

	// Convert config data to JSONB
	configDataBytes, err := json.Marshal(req.ConfigData)
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid config data format")
		return
	}

	var configData models.JSONB
	if err := json.Unmarshal(configDataBytes, &configData); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid config data format")
		return
	}

	// Check if config already exists for this user and type
	var existingConfig models.UIConfig
	if h.db.Where("user_id = ? AND config_type = ?", userID, req.ConfigType).First(&existingConfig).Error == nil {
		utils.ErrorResponse(w, http.StatusConflict, "Configuration already exists for this type")
		return
	}

	config := models.UIConfig{
		UserID:     &userID,
		ConfigType: req.ConfigType,
		ConfigData: configData,
		IsActive:   true,
	}

	if result := h.db.Create(&config); result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to create configuration")
		return
	}

	utils.SuccessResponse(w, config)
}

// UpdateConfig - Update an existing UI configuration
func (h *UIConfigHandler) UpdateConfig(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	configID := vars["id"]

	if configID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Configuration ID is required")
		return
	}

	// Get user ID from context
	userIDStr, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	var req models.UpdateUIConfigRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	var config models.UIConfig
	result := h.db.Where("id = ?", configID).First(&config)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			utils.ErrorResponse(w, http.StatusNotFound, "Configuration not found")
		} else {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch configuration")
		}
		return
	}

	// Check if user owns this config
	if config.UserID == nil || config.UserID.String() != userIDStr {
		utils.ErrorResponse(w, http.StatusForbidden, "You can only update your own configurations")
		return
	}

	// Update config data if provided
	if req.ConfigData != nil {
		configDataBytes, err := json.Marshal(req.ConfigData)
		if err != nil {
			utils.ErrorResponse(w, http.StatusBadRequest, "Invalid config data format")
			return
		}

		var configData models.JSONB
		if err := json.Unmarshal(configDataBytes, &configData); err != nil {
			utils.ErrorResponse(w, http.StatusBadRequest, "Invalid config data format")
			return
		}

		config.ConfigData = configData
	}

	// Update active status if provided
	if req.IsActive != nil {
		config.IsActive = *req.IsActive
	}

	if result := h.db.Save(&config); result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to update configuration")
		return
	}

	utils.SuccessResponse(w, config)
}

// DeleteConfig - Delete a UI configuration
func (h *UIConfigHandler) DeleteConfig(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	configID := vars["id"]

	if configID == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Configuration ID is required")
		return
	}

	// Get user ID from context
	userIDStr, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	var config models.UIConfig
	result := h.db.Where("id = ?", configID).First(&config)
	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			utils.ErrorResponse(w, http.StatusNotFound, "Configuration not found")
		} else {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch configuration")
		}
		return
	}

	// Check if user owns this config
	if config.UserID == nil || config.UserID.String() != userIDStr {
		utils.ErrorResponse(w, http.StatusForbidden, "You can only delete your own configurations")
		return
	}

	if result := h.db.Delete(&config); result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to delete configuration")
		return
	}

	utils.MessageResponse(w, "Configuration deleted successfully")
}

// ResetToDefault - Reset user config to default
func (h *UIConfigHandler) ResetToDefault(w http.ResponseWriter, r *http.Request) {
	configType := r.URL.Query().Get("type")
	if configType == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Config type is required")
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

	// Delete user-specific config for this type
	result := h.db.Where("user_id = ? AND config_type = ?", userID, configType).Delete(&models.UIConfig{})
	if result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to reset configuration")
		return
	}

	// Get default config
	var defaultConfig models.UIConfig
	if h.db.Where("user_id IS NULL AND config_type = ? AND is_active = ?", configType, true).First(&defaultConfig).Error != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "Default configuration not found")
		return
	}

	utils.SuccessResponse(w, map[string]interface{}{
		"message": "Configuration reset to default",
		"config":  defaultConfig,
	})
}
