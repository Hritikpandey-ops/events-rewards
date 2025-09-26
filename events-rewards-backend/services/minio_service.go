package services

import (
	"context"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

type MinIOService struct {
	client     *minio.Client
	bucketName string
}

type MinIOConfig struct {
	Endpoint   string
	AccessKey  string
	SecretKey  string
	BucketName string
	UseSSL     bool
}

func NewMinIOService(config MinIOConfig) (*MinIOService, error) {
	// Initialize MinIO client
	client, err := minio.New(config.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(config.AccessKey, config.SecretKey, ""),
		Secure: config.UseSSL,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create MinIO client: %w", err)
	}

	service := &MinIOService{
		client:     client,
		bucketName: config.BucketName,
	}

	// Create bucket if it doesn't exist
	if err := service.createBucketIfNotExists(); err != nil {
		return nil, err
	}

	return service, nil
}

func (s *MinIOService) createBucketIfNotExists() error {
	ctx := context.Background()

	exists, err := s.client.BucketExists(ctx, s.bucketName)
	if err != nil {
		return fmt.Errorf("failed to check bucket existence: %w", err)
	}

	if !exists {
		err = s.client.MakeBucket(ctx, s.bucketName, minio.MakeBucketOptions{})
		if err != nil {
			return fmt.Errorf("failed to create bucket: %w", err)
		}
		log.Printf("Successfully created bucket: %s", s.bucketName)
	}

	return nil
}

func (s *MinIOService) UploadFile(file multipart.File, header *multipart.FileHeader, userID uuid.UUID, fileType string) (string, error) {
	// Validate file type
	allowedTypes := map[string][]string{
		"selfie": {"image/jpeg", "image/png", "image/jpg"},
		"voice":  {"audio/mpeg", "audio/wav", "audio/mp3", "audio/m4a"},
	}

	contentType := header.Header.Get("Content-Type")
	if allowed, exists := allowedTypes[fileType]; exists {
		valid := false
		for _, allowedType := range allowed {
			if contentType == allowedType {
				valid = true
				break
			}
		}
		if !valid {
			return "", fmt.Errorf("invalid file type: %s. Allowed types for %s: %v", contentType, fileType, allowed)
		}
	} else {
		return "", fmt.Errorf("unsupported file type: %s", fileType)
	}

	// Generate unique filename
	ext := filepath.Ext(header.Filename)
	timestamp := time.Now().Format("20060102_150405")
	filename := fmt.Sprintf("%s/%s_%s_%s%s", fileType, userID.String(), timestamp, generateRandomString(8), ext)

	// Upload file to MinIO
	ctx := context.Background()
	_, err := s.client.PutObject(ctx, s.bucketName, filename, file, header.Size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return "", fmt.Errorf("failed to upload file to MinIO: %w", err)
	}

	// Return the file path/URL
	return filename, nil
}

func (s *MinIOService) GetFileURL(filename string) (string, error) {
	// Generate a presigned URL for file access (valid for 7 days)
	ctx := context.Background()
	presignedURL, err := s.client.PresignedGetObject(ctx, s.bucketName, filename, time.Hour*24*7, nil)
	if err != nil {
		return "", fmt.Errorf("failed to generate presigned URL: %w", err)
	}

	return presignedURL.String(), nil
}

func (s *MinIOService) DeleteFile(filename string) error {
	ctx := context.Background()
	err := s.client.RemoveObject(ctx, s.bucketName, filename, minio.RemoveObjectOptions{})
	if err != nil {
		return fmt.Errorf("failed to delete file from MinIO: %w", err)
	}

	return nil
}

func (s *MinIOService) GetFile(filename string) (io.Reader, error) {
	ctx := context.Background()
	object, err := s.client.GetObject(ctx, s.bucketName, filename, minio.GetObjectOptions{})
	if err != nil {
		return nil, fmt.Errorf("failed to get file from MinIO: %w", err)
	}

	return object, nil
}

// Helper function to generate random string
func generateRandomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyz0123456789"
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[time.Now().UnixNano()%int64(len(charset))]
	}
	return string(b)
}

// Helper function to validate file extension
func (s *MinIOService) ValidateFileExtension(filename, fileType string) bool {
	ext := strings.ToLower(filepath.Ext(filename))

	switch fileType {
	case "selfie":
		return ext == ".jpg" || ext == ".jpeg" || ext == ".png"
	case "voice":
		return ext == ".mp3" || ext == ".wav" || ext == ".m4a" || ext == ".mpeg"
	default:
		return false
	}
}
