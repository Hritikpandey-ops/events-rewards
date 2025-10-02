package models

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// JSONB type for PostgreSQL JSONB columns
type JSONB map[string]interface{}

func (j JSONB) Value() (driver.Value, error) {
	return json.Marshal(j)
}

func (j *JSONB) Scan(value interface{}) error {
	if value == nil {
		*j = make(map[string]interface{})
		return nil
	}

	bytes, ok := value.([]byte)
	if !ok {
		return errors.New("type assertion to []byte failed")
	}

	return json.Unmarshal(bytes, j)
}

type User struct {
	ID           uuid.UUID      `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	Email        string         `json:"email" gorm:"type:varchar(255);unique;not null" validate:"required,email"`
	PasswordHash string         `json:"-" gorm:"not null" validate:"required"`
	FirstName    string         `json:"first_name" gorm:"not null" validate:"required,min=2"`
	LastName     string         `json:"last_name" gorm:"not null" validate:"required,min=2"`
	Phone        *string        `json:"phone"`
	IsVerified   bool           `json:"is_verified" gorm:"default:false"`
	IsActive     bool           `json:"is_active" gorm:"default:true"`
	SelfiePath   *string        `json:"selfie_path"`
	VoicePath    *string        `json:"voice_path"`
	DeviceID     *string        `json:"device_id"`
	DeviceInfo   JSONB          `json:"device_info" gorm:"type:jsonb"`
	Location     JSONB          `json:"location_info" gorm:"type:jsonb"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `json:"-" gorm:"index"`
}

// TableName specifies the table name for User model
func (User) TableName() string {
	return "users"
}
