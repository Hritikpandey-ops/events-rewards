package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"log"
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

	location, _ := time.LoadLocation("Asia/Kolkata")
	now := time.Now().In(location)
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)

	// Check daily spin limits (3 spins per day)
	var spinAttempt models.SpinAttempt
	result := h.db.Where("user_id = ? AND attempt_date = ?", userID, today).First(&spinAttempt)

	if result.Error == nil {
		// User has spun today - check if limit reached
		if spinAttempt.AttemptsCount >= 3 {
			utils.ErrorResponse(w, http.StatusTooManyRequests, "Daily spin limit reached")
			return
		}
		// Update existing record
		spinAttempt.AttemptsCount++
		spinAttempt.LastAttempt = now
		h.db.Save(&spinAttempt)
	} else if result.Error == gorm.ErrRecordNotFound {

		spinAttempt = models.SpinAttempt{
			ID:            uuid.New(),
			UserID:        userID,
			AttemptDate:   today,
			AttemptsCount: 1,
			LastAttempt:   now,
		}
		h.db.Create(&spinAttempt)
	} else {
		// Database error
		utils.ErrorResponse(w, http.StatusInternalServerError, "Database error")
		return
	}

	// Get all available rewards
	var rewards []models.Reward
	h.db.Where("is_active = true").Find(&rewards)

	if len(rewards) == 0 {
		utils.ErrorResponse(w, http.StatusInternalServerError, "No rewards available")
		return
	}

	// Select reward based on probability
	selectedReward := h.selectRewardByProbability(rewards)

	if selectedReward.RewardType == nil || *selectedReward.RewardType != "none" {
		expiryTime := now.AddDate(0, 0, 7) // 7 days from now
		claimCode := h.generateClaimCode()

		userReward := models.UserReward{
			ID:        uuid.New(),
			UserID:    userID,
			RewardID:  selectedReward.ID,
			CreatedAt: now,
			UpdatedAt: now,
			Status:    "pending",
			ExpiresAt: &expiryTime,
			ClaimCode: &claimCode,
		}

		// Save to database
		if err := h.db.Create(&userReward).Error; err != nil {
			utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to save reward")
			return
		}

		// Load reward details for response
		h.db.Preload("Reward").First(&userReward, userReward.ID)

		// Prepare response for REAL rewards
		response := map[string]interface{}{
			"success":     true,
			"reward":      selectedReward,
			"message":     "Congratulations! You won: " + selectedReward.Name,
			"user_reward": userReward,
			"claim_code":  claimCode,
			"expires_at":  &expiryTime,
		}

		utils.SuccessResponse(w, response)
	} else {
		response := map[string]interface{}{
			"success": true,
			"reward":  selectedReward,
			"message": "Better luck next time!",
		}

		utils.SuccessResponse(w, response)
	}
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

	location, _ := time.LoadLocation("Asia/Kolkata")
	claimTime := time.Now().In(location)

	userReward.Status = "claimed"
	userReward.ClaimedAt = &claimTime
	userReward.UpdatedAt = claimTime

	log.Printf("DEBUG: Setting claimed_at to: %v (IST)", claimTime)
	log.Printf("DEBUG: Date should show as: %s", claimTime.Format("02/01/2006"))

	if h.db.Save(&userReward).Error != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to claim reward")
		return
	}

	var verifyReward models.UserReward
	h.db.Where("id = ?", userReward.ID).First(&verifyReward)
	log.Printf("DEBUG: Database shows claimed_at as: %v", verifyReward.ClaimedAt)

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

// GetRemainingSpins - Get user's remaining daily spins
func (h *LuckyDrawHandler) GetRemainingSpins(w http.ResponseWriter, r *http.Request) {
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

	location, _ := time.LoadLocation("Asia/Kolkata")
	now := time.Now().In(location)

	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)

	var spinAttempt models.SpinAttempt
	result := h.db.Where("user_id = ? AND attempt_date = ?", userID, today).First(&spinAttempt)

	remainingSpins := 3
	spinsUsed := 0
	var lastSpin *time.Time

	if result.Error == nil {
		spinsUsed = spinAttempt.AttemptsCount
		remainingSpins = 3 - spinsUsed
		if remainingSpins < 0 {
			remainingSpins = 0
		}
		if !spinAttempt.LastAttempt.IsZero() {
			lastSpin = &spinAttempt.LastAttempt
		}
	} else if result.Error != gorm.ErrRecordNotFound {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to check spin attempts")
		return
	}
	response := map[string]interface{}{
		"remaining_spins":   remainingSpins,
		"total_daily_spins": 3,
		"spins_used_today":  spinsUsed,
		"last_spin":         lastSpin,
		"can_spin_today":    remainingSpins > 0,
		"debug_today_date":  today.Format("2006-01-02"),
	}

	utils.SuccessResponse(w, response)
}
