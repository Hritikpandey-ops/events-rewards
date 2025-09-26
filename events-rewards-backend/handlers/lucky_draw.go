package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"math"
	"net/http"
	"time"

	"github.com/Hritikpandey-ops/events-rewards-backend/models"
	"github.com/Hritikpandey-ops/events-rewards-backend/utils"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type LuckyDrawHandler struct {
	db *gorm.DB
}

func NewLuckyDrawHandler(db *gorm.DB) *LuckyDrawHandler {
	return &LuckyDrawHandler{db: db}
}

// Spin - Perform a lucky draw spin
func (h *LuckyDrawHandler) Spin(w http.ResponseWriter, r *http.Request) {
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

	// Check daily spin limits (e.g., 3 spins per day)
	today := time.Now().Truncate(24 * time.Hour)
	var spinAttempt models.SpinAttempt

	result := h.db.Where("user_id = ? AND attempt_date = ?", userID, today).First(&spinAttempt)

	if result.Error == nil {
		// User has spun today, check if they've reached the limit
		if spinAttempt.AttemptsCount >= 3 {
			utils.ErrorResponse(w, http.StatusTooManyRequests, "Daily spin limit reached (3 spins per day)")
			return
		}

		// Increment attempts count
		spinAttempt.AttemptsCount++
		spinAttempt.LastAttempt = time.Now()
		h.db.Save(&spinAttempt)
	} else if result.Error == gorm.ErrRecordNotFound {
		// First spin of the day
		spinAttempt = models.SpinAttempt{
			UserID:        userID,
			AttemptDate:   today,
			AttemptsCount: 1,
			LastAttempt:   time.Now(),
		}
		h.db.Create(&spinAttempt)
	} else {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to check spin attempts")
		return
	}

	// Get all active rewards
	var rewards []models.Reward
	if h.db.Where("is_active = ? AND (total_available IS NULL OR total_available > total_claimed)", true).Find(&rewards).Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch rewards")
		return
	}

	if len(rewards) == 0 {
		utils.ErrorResponse(w, http.StatusServiceUnavailable, "No rewards available")
		return
	}

	// Perform weighted random selection
	selectedReward := h.selectRewardByProbability(rewards)
	if selectedReward == nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to select reward")
		return
	}

	var claimCode *string
	var expiresAt *time.Time

	// If it's not a "no reward" result, create a user reward record
	if selectedReward.RewardType == nil || *selectedReward.RewardType != "none" {
		// Generate claim code
		code := h.generateClaimCode()
		claimCode = &code

		// Set expiration (e.g., 30 days from now)
		expiry := time.Now().AddDate(0, 0, 30)
		expiresAt = &expiry

		// Create user reward record
		userReward := models.UserReward{
			UserID:    userID,
			RewardID:  selectedReward.ID,
			ClaimCode: claimCode,
			ExpiresAt: expiresAt,
			Status:    "pending",
		}

		tx := h.db.Begin()

		if tx.Create(&userReward).Error != nil {
			tx.Rollback()
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to create user reward")
			return
		}

		// Update reward claimed count
		if tx.Model(selectedReward).Update("total_claimed", gorm.Expr("total_claimed + 1")).Error != nil {
			tx.Rollback()
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to update reward count")
			return
		}

		tx.Commit()
	}

	response := models.SpinResponse{
		Success:   true,
		Reward:    selectedReward,
		ClaimCode: claimCode,
		ExpiresAt: expiresAt,
	}

	if selectedReward.RewardType != nil && *selectedReward.RewardType == "none" {
		response.Message = "Better luck next time!"
	} else {
		response.Message = "Congratulations! You won: " + selectedReward.Name
	}

	utils.SuccessResponse(w, response)
}

// selectRewardByProbability selects a reward based on probability weights
func (h *LuckyDrawHandler) selectRewardByProbability(rewards []models.Reward) *models.Reward {
	// Calculate total probability
	var totalProbability float64
	for _, reward := range rewards {
		totalProbability += reward.Probability
	}

	// Generate random number between 0 and totalProbability
	randomBytes := make([]byte, 8)
	rand.Read(randomBytes)

	// Convert bytes to float64 between 0 and 1
	randomFloat := float64(uint64(randomBytes[0])<<56|uint64(randomBytes[1])<<48|
		uint64(randomBytes[2])<<40|uint64(randomBytes[3])<<32|
		uint64(randomBytes[4])<<24|uint64(randomBytes[5])<<16|
		uint64(randomBytes[6])<<8|uint64(randomBytes[7])) / math.MaxUint64

	randomValue := randomFloat * totalProbability

	// Select reward based on cumulative probability
	var cumulative float64
	for _, reward := range rewards {
		cumulative += reward.Probability
		if randomValue <= cumulative {
			return &reward
		}
	}

	// Fallback to last reward (should not happen)
	return &rewards[len(rewards)-1]
}

// generateClaimCode generates a random claim code
func (h *LuckyDrawHandler) generateClaimCode() string {
	bytes := make([]byte, 6)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)[:12]
}

// GetRewards - Get all available rewards
func (h *LuckyDrawHandler) GetRewards(w http.ResponseWriter, r *http.Request) {
	var rewards []models.Reward
	result := h.db.Where("is_active = ?", true).Order("probability DESC").Find(&rewards)

	if result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch rewards")
		return
	}

	// Don't expose exact probabilities to frontend for security
	type RewardResponse struct {
		ID          uuid.UUID `json:"id"`
		Name        string    `json:"name"`
		Description *string   `json:"description"`
		RewardType  *string   `json:"reward_type"`
		Value       *float64  `json:"value"`
		IsActive    bool      `json:"is_active"`
	}

	var responseRewards []RewardResponse
	for _, reward := range rewards {
		responseRewards = append(responseRewards, RewardResponse{
			ID:          reward.ID,
			Name:        reward.Name,
			Description: reward.Description,
			RewardType:  reward.RewardType,
			Value:       reward.Value,
			IsActive:    reward.IsActive,
		})
	}

	utils.SuccessResponse(w, responseRewards)
}

// GetUserRewards - Get user's won rewards
func (h *LuckyDrawHandler) GetUserRewards(w http.ResponseWriter, r *http.Request) {
	// Get user ID from context
	userIDStr, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	var userRewards []models.UserReward
	result := h.db.
		Preload("Reward").
		Where("user_id = ?", userIDStr).
		Order("claimed_at DESC").
		Find(&userRewards)

	if result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch user rewards")
		return
	}

	utils.SuccessResponse(w, userRewards)
}

// ClaimReward - Claim a reward using claim code
func (h *LuckyDrawHandler) ClaimReward(w http.ResponseWriter, r *http.Request) {
	// Get user ID from context
	userIDStr, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	var req models.RewardClaimRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.ClaimCode == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Claim code is required")
		return
	}

	var userReward models.UserReward
	result := h.db.
		Preload("Reward").
		Where("user_id = ? AND claim_code = ? AND status = ?", userIDStr, req.ClaimCode, "pending").
		First(&userReward)

	if result.Error != nil {
		if result.Error == gorm.ErrRecordNotFound {
			utils.ErrorResponse(w, http.StatusNotFound, "Invalid claim code or reward already claimed")
		} else {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch reward")
		}
		return
	}

	// Check if reward has expired
	if userReward.ExpiresAt != nil && userReward.ExpiresAt.Before(time.Now()) {
		utils.ErrorResponse(w, http.StatusBadRequest, "Reward has expired")
		return
	}

	// Update status to claimed
	userReward.Status = "claimed"
	if h.db.Save(&userReward).Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to claim reward")
		return
	}

	utils.SuccessResponse(w, map[string]interface{}{
		"message": "Reward claimed successfully",
		"reward":  userReward,
	})
}

// GetSpinHistory - Get user's spin history
func (h *LuckyDrawHandler) GetSpinHistory(w http.ResponseWriter, r *http.Request) {
	// Get user ID from context
	userIDStr, ok := r.Context().Value("user_id").(string)
	if !ok {
		utils.ErrorResponse(w, http.StatusUnauthorized, "User not authenticated")
		return
	}

	var spinAttempts []models.SpinAttempt
	result := h.db.
		Where("user_id = ?", userIDStr).
		Order("attempt_date DESC").
		Limit(30). // Last 30 days
		Find(&spinAttempts)

	if result.Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to fetch spin history")
		return
	}

	utils.SuccessResponse(w, spinAttempts)
}

// GetUserStats - Get user's spin and reward statistics
func (h *LuckyDrawHandler) GetUserStats(w http.ResponseWriter, r *http.Request) {
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

	// Calculate statistics
	var totalSpins int64
	h.db.Model(&models.SpinAttempt{}).
		Select("COALESCE(SUM(attempts_count), 0)").
		Where("user_id = ?", userID).
		Scan(&totalSpins)

	var totalWins int64
	h.db.Model(&models.UserReward{}).
		Where("user_id = ?", userID).
		Count(&totalWins)

	var pendingRewards int64
	h.db.Model(&models.UserReward{}).
		Where("user_id = ? AND status = ?", userID, "pending").
		Count(&pendingRewards)

	var claimedRewards int64
	h.db.Model(&models.UserReward{}).
		Where("user_id = ? AND status = ?", userID, "claimed").
		Count(&claimedRewards)

	stats := models.UserRewardStats{
		TotalSpins:     int(totalSpins),
		TotalWins:      int(totalWins),
		PendingRewards: int(pendingRewards),
		ClaimedRewards: int(claimedRewards),
	}

	utils.SuccessResponse(w, stats)
}
