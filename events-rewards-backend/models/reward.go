package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Reward model
type Reward struct {
	ID             uuid.UUID      `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	Name           string         `json:"name" gorm:"not null"`
	Description    *string        `json:"description"`
	RewardType     *string        `json:"reward_type"`
	Value          *float64       `json:"value" gorm:"type:decimal(10,2)"`
	Probability    float64        `json:"probability" gorm:"type:decimal(5,4);not null"`
	TotalAvailable *int           `json:"total_available"`
	TotalClaimed   int            `json:"total_claimed" gorm:"default:0"`
	IsActive       bool           `json:"is_active" gorm:"default:true"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
	DeletedAt      gorm.DeletedAt `json:"-" gorm:"index"`

	// Relationships
	UserRewards []UserReward `json:"user_rewards,omitempty" gorm:"foreignKey:RewardID"`
}

// TableName specifies the table name for Reward model
func (Reward) TableName() string {
	return "rewards"
}

// UserReward model
type UserReward struct {
	ID        uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	UserID    uuid.UUID  `json:"user_id" gorm:"not null"`
	RewardID  uuid.UUID  `json:"reward_id" gorm:"not null"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
	ClaimedAt *time.Time `json:"claimed_at"`
	Status    string     `json:"status" gorm:"default:pending"`
	ClaimCode *string    `json:"claim_code"`
	ExpiresAt *time.Time `json:"expires_at"`

	// Relationships
	User   User   `json:"user,omitempty" gorm:"foreignKey:UserID"`
	Reward Reward `json:"reward,omitempty" gorm:"foreignKey:RewardID"`
}

// TableName specifies the table name for UserReward model
func (UserReward) TableName() string {
	return "user_rewards"
}

// SpinAttempt model
type SpinAttempt struct {
	ID            uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	UserID        uuid.UUID `json:"user_id" gorm:"not null"`
	AttemptDate   time.Time `json:"attempt_date" gorm:"type:date;not null"`
	AttemptsCount int       `json:"attempts_count" gorm:"default:1"`
	LastAttempt   time.Time `json:"last_attempt" gorm:"default:CURRENT_TIMESTAMP"`

	// Relationships
	User User `json:"user,omitempty" gorm:"foreignKey:UserID"`
}

// TableName specifies the table name for SpinAttempt model
func (SpinAttempt) TableName() string {
	return "spin_attempts"
}

// Lucky Draw request/response models
type SpinRequest struct {
	UserID string `json:"user_id"`
}

type SpinResponse struct {
	Success   bool       `json:"success"`
	Reward    *Reward    `json:"reward"`
	ClaimCode *string    `json:"claim_code,omitempty"`
	Message   string     `json:"message"`
	ExpiresAt *time.Time `json:"expires_at,omitempty"`
}

type RewardClaimRequest struct {
	ClaimCode string `json:"claim_code" validate:"required"`
}

// Reward statistics
type RewardStats struct {
	TotalRewards   int     `json:"total_rewards"`
	TotalClaimed   int     `json:"total_claimed"`
	TotalAvailable int     `json:"total_available"`
	ClaimRate      float64 `json:"claim_rate"`
}

type UserRewardStats struct {
	TotalSpins     int `json:"total_spins"`
	TotalWins      int `json:"total_wins"`
	PendingRewards int `json:"pending_rewards"`
	ClaimedRewards int `json:"claimed_rewards"`
}
