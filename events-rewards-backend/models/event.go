package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Event model
type Event struct {
	ID                  uuid.UUID      `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	Title               string         `json:"title" gorm:"not null"`
	Description         *string        `json:"description"`
	EventDate           time.Time      `json:"event_date" gorm:"not null"`
	Location            *string        `json:"location"`
	MaxParticipants     *int           `json:"max_participants"`
	CurrentParticipants int            `json:"current_participants" gorm:"default:0"`
	BannerImage         *string        `json:"banner_image"`
	Category            *string        `json:"category"`
	IsActive            bool           `json:"is_active" gorm:"default:true"`
	CreatedBy           *uuid.UUID     `json:"created_by"`
	CreatedAt           time.Time      `json:"created_at"`
	UpdatedAt           time.Time      `json:"updated_at"`
	DeletedAt           gorm.DeletedAt `json:"-" gorm:"index"`

	// Relationships
	Creator       *User               `json:"creator,omitempty" gorm:"foreignKey:CreatedBy"`
	Registrations []EventRegistration `json:"registrations,omitempty" gorm:"foreignKey:EventID"`
}

// TableName specifies the table name for Event model
func (Event) TableName() string {
	return "events"
}

// EventRegistration model
type EventRegistration struct {
	ID               uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	UserID           uuid.UUID `json:"user_id" gorm:"not null"`
	EventID          uuid.UUID `json:"event_id" gorm:"not null"`
	RegistrationDate time.Time `json:"registration_date" gorm:"default:CURRENT_TIMESTAMP"`
	Status           string    `json:"status" gorm:"default:registered"`

	// Relationships
	User  User  `json:"user,omitempty" gorm:"foreignKey:UserID"`
	Event Event `json:"event,omitempty" gorm:"foreignKey:EventID"`
}

// TableName specifies the table name for EventRegistration model
func (EventRegistration) TableName() string {
	return "event_registrations"
}

// Event filters and request models
type EventFilter struct {
	Category  *string    `json:"category"`
	DateFrom  *time.Time `json:"date_from"`
	DateTo    *time.Time `json:"date_to"`
	Location  *string    `json:"location"`
	IsActive  *bool      `json:"is_active"`
	CreatedBy *uuid.UUID `json:"created_by"`
}

type CreateEventRequest struct {
	Title           string    `json:"title" validate:"required"`
	Description     string    `json:"description"`
	EventDate       time.Time `json:"event_date" validate:"required"`
	Location        string    `json:"location"`
	MaxParticipants int       `json:"max_participants"`
	BannerImage     string    `json:"banner_image"`
	Category        string    `json:"category"`
}

type UpdateEventRequest struct {
	Title           *string    `json:"title"`
	Description     *string    `json:"description"`
	EventDate       *time.Time `json:"event_date"`
	Location        *string    `json:"location"`
	MaxParticipants *int       `json:"max_participants"`
	BannerImage     *string    `json:"banner_image"`
	Category        *string    `json:"category"`
	IsActive        *bool      `json:"is_active"`
}
