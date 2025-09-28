package handlers

import (
	"net/http"

	"github.com/Hritikpandey-ops/events-rewards-backend/models"
	"github.com/Hritikpandey-ops/events-rewards-backend/utils"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type UserHandler struct {
	db *gorm.DB
}

func NewUserHandler(db *gorm.DB) *UserHandler {
	return &UserHandler{db: db}
}

// GetUserRewards - Get all rewards for the authenticated user
func (h *UserHandler) GetUserRewards(w http.ResponseWriter, r *http.Request) {
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

	var userRewards []models.UserReward
	result := h.db.Preload("Reward").Where("user_id = ?", userID).
		Order("created_at DESC").Find(&userRewards)

	if result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch user rewards")
		return
	}

	utils.SuccessResponse(w, userRewards)
}

// GetUserStats - Get user statistics
func (h *UserHandler) GetUserStats(w http.ResponseWriter, r *http.Request) {
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

	// Count different types of rewards
	var totalRewards, pendingRewards, claimedRewards int64

	h.db.Model(&models.UserReward{}).Where("user_id = ?", userID).Count(&totalRewards)
	h.db.Model(&models.UserReward{}).Where("user_id = ? AND status = ?", userID, "pending").Count(&pendingRewards)
	h.db.Model(&models.UserReward{}).Where("user_id = ? AND status = ?", userID, "claimed").Count(&claimedRewards)

	// Count total spins (from spin attempts)
	var totalSpins int64
	h.db.Model(&models.SpinAttempt{}).Where("user_id = ?", userID).
		Select("COALESCE(SUM(attempts_count), 0)").Scan(&totalSpins)

	stats := map[string]interface{}{
		"total_spins":     totalSpins,
		"total_wins":      totalRewards,
		"pending_rewards": pendingRewards,
		"claimed_rewards": claimedRewards,
	}

	utils.SuccessResponse(w, stats)
}
