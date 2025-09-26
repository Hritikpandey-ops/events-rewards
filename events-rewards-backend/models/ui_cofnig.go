package models

import (
	"time"

	"github.com/google/uuid"
)

// UIConfig model
type UIConfig struct {
	ID         uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	UserID     *uuid.UUID `json:"user_id"`
	ConfigType string     `json:"config_type" gorm:"not null"`
	ConfigData JSONB      `json:"config_data" gorm:"type:jsonb;not null"`
	IsActive   bool       `json:"is_active" gorm:"default:true"`
	CreatedAt  time.Time  `json:"created_at"`
	UpdatedAt  time.Time  `json:"updated_at"`

	// Relationships
	User *User `json:"user,omitempty" gorm:"foreignKey:UserID"`
}

// TableName specifies the table name for UIConfig model
func (UIConfig) TableName() string {
	return "ui_configs"
}

// UI Config request models
type UIModule struct {
	Type    string                 `json:"type"`
	Enabled bool                   `json:"enabled"`
	Order   int                    `json:"order"`
	Config  map[string]interface{} `json:"config,omitempty"`
	Limit   *int                   `json:"limit,omitempty"`
}

type UITheme struct {
	PrimaryColor    string  `json:"primary_color"`
	SecondaryColor  string  `json:"secondary_color"`
	BackgroundColor *string `json:"background_color,omitempty"`
	TextColor       *string `json:"text_color,omitempty"`
}

type HomeUIConfig struct {
	Modules []UIModule `json:"modules"`
	Theme   UITheme    `json:"theme"`
}

type EventsUIConfig struct {
	Filters     []string `json:"filters"`
	SortOptions []string `json:"sort_options"`
	DisplayMode string   `json:"display_mode"`
}

type CreateUIConfigRequest struct {
	ConfigType string      `json:"config_type" validate:"required"`
	ConfigData interface{} `json:"config_data" validate:"required"`
}

type UpdateUIConfigRequest struct {
	ConfigData interface{} `json:"config_data" validate:"required"`
	IsActive   *bool       `json:"is_active"`
}
