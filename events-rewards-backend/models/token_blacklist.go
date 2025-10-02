package models

import (
	"time"

	"github.com/google/uuid"
)

type TokenBlacklist struct {
	ID        uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	Token     string    `json:"token" gorm:"type:text;not null;uniqueIndex"`
	UserID    uuid.UUID `json:"user_id" gorm:"type:uuid;not null"`
	ExpiresAt time.Time `json:"expires_at" gorm:"not null"`
	CreatedAt time.Time `json:"created_at"`
}

func (TokenBlacklist) TableName() string {
	return "token_blacklist"
}
