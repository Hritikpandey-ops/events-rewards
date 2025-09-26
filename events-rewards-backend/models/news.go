package models

import (
    "time"

    "github.com/google/uuid"
    "gorm.io/gorm"
)

// News model
type News struct {
    ID          uuid.UUID      `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
    Title       string         `json:"title" gorm:"not null"`
    Content     string         `json:"content" gorm:"not null"`
    Summary     *string        `json:"summary"`
    ImageURL    *string        `json:"image_url"`
    Category    *string        `json:"category"`
    IsPublished bool           `json:"is_published" gorm:"default:false"`
    PublishDate *time.Time     `json:"publish_date"`
    CreatedAt   time.Time      `json:"created_at"`
    UpdatedAt   time.Time      `json:"updated_at"`
    DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`
}

// TableName specifies the table name for News model
func (News) TableName() string {
    return "news"
}

// News request models
type CreateNewsRequest struct {
    Title       string `json:"title" validate:"required"`
    Content     string `json:"content" validate:"required"`
    Summary     string `json:"summary"`
    ImageURL    string `json:"image_url"`
    Category    string `json:"category"`
    IsPublished bool   `json:"is_published"`
}

type UpdateNewsRequest struct {
    Title       *string `json:"title"`
    Content     *string `json:"content"`
    Summary     *string `json:"summary"`
    ImageURL    *string `json:"image_url"`
    Category    *string `json:"category"`
    IsPublished *bool   `json:"is_published"`
}

type NewsFilter struct {
    Category    *string `json:"category"`
    IsPublished *bool   `json:"is_published"`
}
