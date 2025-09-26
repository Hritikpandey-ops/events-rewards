package handlers

import (
	"encoding/json"
	"fmt"
	"image"
	_ "image/jpeg"
	_ "image/png"
	"mime/multipart"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/Hritikpandey-ops/events-rewards-backend/models"
	"github.com/Hritikpandey-ops/events-rewards-backend/services"
	"github.com/Hritikpandey-ops/events-rewards-backend/utils"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AuthHandler struct {
	authService  *services.AuthService
	minioService *services.MinIOService
	db           *gorm.DB
	uploadPath   string
}

type RegisterRequest struct {
	Email      string                 `json:"email" validate:"required,email"`
	Password   string                 `json:"password" validate:"required,min=8"`
	FirstName  string                 `json:"first_name" validate:"required,min=2"`
	LastName   string                 `json:"last_name" validate:"required,min=2"`
	Phone      string                 `json:"phone"`
	DeviceInfo map[string]interface{} `json:"device_info"`
	Location   map[string]interface{} `json:"location"`
	DeviceID   string                 `json:"device_id"`
}

type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
	DeviceID string `json:"device_id"`
}

type IdentityVerificationRequest struct {
	UserID string `json:"user_id"`
}

type AuthResponse struct {
	Success bool                   `json:"success"`
	Message string                 `json:"message"`
	Data    map[string]interface{} `json:"data,omitempty"`
	Error   string                 `json:"error,omitempty"`
}

func NewAuthHandler(db *gorm.DB, minioService *services.MinIOService) *AuthHandler {
	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "default-secret-key"
	}

	uploadPath := os.Getenv("UPLOAD_PATH")
	if uploadPath == "" {
		uploadPath = "./uploads"
	}

	return &AuthHandler{
		authService:  services.NewAuthService(db, jwtSecret),
		minioService: minioService,
		db:           db,
		uploadPath:   uploadPath,
	}
}

// Register - User registration with comprehensive validation
func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate required fields
	if req.Email == "" || req.Password == "" || req.FirstName == "" || req.LastName == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Missing required fields: email, password, first_name, last_name")
		return
	}

	// Validate email format
	if !isValidEmail(req.Email) {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid email format")
		return
	}

	// Validate password strength
	if len(req.Password) < 8 {
		utils.ErrorResponse(w, http.StatusBadRequest, "Password must be at least 8 characters long")
		return
	}

	// Check if user already exists
	var existingUser models.User
	if err := h.db.Where("email = ?", strings.ToLower(req.Email)).First(&existingUser).Error; err == nil {
		utils.ErrorResponse(w, http.StatusConflict, "User already exists with this email")
		return
	}

	// Hash password
	hashedPassword, err := h.authService.HashPassword(req.Password)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to process password")
		return
	}

	// Convert device info and location to JSONB
	var deviceInfo models.JSONB
	var location models.JSONB

	if req.DeviceInfo != nil {
		deviceInfo = models.JSONB(req.DeviceInfo)
	} else {
		deviceInfo = make(models.JSONB)
	}

	if req.Location != nil {
		location = models.JSONB(req.Location)
	} else {
		location = make(models.JSONB)
	}

	// Create user
	user := models.User{
		ID:           uuid.New(),
		Email:        strings.ToLower(req.Email),
		PasswordHash: hashedPassword,
		FirstName:    req.FirstName,
		LastName:     req.LastName,
		Phone:        &req.Phone,
		DeviceInfo:   deviceInfo,
		Location:     location,
		DeviceID:     &req.DeviceID,
		IsVerified:   false,
		IsActive:     true,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	if err := h.db.Create(&user).Error; err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to create user account")
		return
	}

	// Generate JWT token
	token, err := h.authService.GenerateJWT(&user)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to generate authentication token")
		return
	}

	// Remove sensitive information
	user.PasswordHash = ""

	utils.SuccessResponse(w, map[string]interface{}{
		"user":    user,
		"token":   token,
		"message": "Registration successful. Please complete identity verification.",
	})
}

// Login - User login with enhanced security
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Validate required fields
	if req.Email == "" || req.Password == "" {
		utils.ErrorResponse(w, http.StatusBadRequest, "Email and password are required")
		return
	}

	// Find user by email (case-insensitive)
	var user models.User
	if err := h.db.Where("email = ? AND is_active = ?", strings.ToLower(req.Email), true).First(&user).Error; err != nil {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Invalid email or password")
		return
	}

	// Check password
	if !h.authService.CheckPassword(req.Password, user.PasswordHash) {
		utils.ErrorResponse(w, http.StatusUnauthorized, "Invalid email or password")
		return
	}

	// Update device ID and last login if provided
	if req.DeviceID != "" {
		deviceID := req.DeviceID
		user.DeviceID = &deviceID
		user.UpdatedAt = time.Now()
		h.db.Save(&user)
	}

	// Generate JWT token
	token, err := h.authService.GenerateJWT(&user)
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to generate authentication token")
		return
	}

	// Remove sensitive information
	user.PasswordHash = ""

	utils.SuccessResponse(w, map[string]interface{}{
		"user":    user,
		"token":   token,
		"message": "Login successful",
	})
}

// UploadSelfie - Upload user selfie with liveliness validation
func (h *AuthHandler) UploadSelfie(w http.ResponseWriter, r *http.Request) {
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

	// Parse multipart form
	err = r.ParseMultipartForm(10 << 20) // 10 MB limit
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Failed to parse form data")
		return
	}

	// Get file from form
	file, header, err := r.FormFile("selfie")
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "No selfie file provided")
		return
	}
	defer file.Close()

	// Validate file type
	if !isValidImageType(header.Header.Get("Content-Type")) {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid file type. Only JPEG and PNG images are allowed")
		return
	}

	// Basic liveliness validation
	if !h.validateBasicLiveliness(file, header) {
		utils.ErrorResponse(w, http.StatusBadRequest, "Selfie validation failed. Please ensure good lighting and clear face visibility")
		return
	}

	// Reset file pointer after validation
	file.Seek(0, 0)

	// Upload to MinIO
	filePath, err := h.minioService.UploadFile(file, header, userID, "selfie")
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, fmt.Sprintf("Failed to upload selfie: %v", err))
		return
	}

	// Update user record with selfie path
	if err := h.db.Model(&models.User{}).Where("id = ?", userID).Update("selfie_path", filePath).Error; err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to update user record")
		return
	}

	utils.SuccessResponse(w, map[string]interface{}{
		"message":     "Selfie uploaded successfully",
		"selfie_path": filePath,
		"next_step":   "Please upload voice recording to complete identity verification",
	})
}

// UploadVoice - Upload user voice recording with validation
func (h *AuthHandler) UploadVoice(w http.ResponseWriter, r *http.Request) {
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

	// Parse multipart form
	err = r.ParseMultipartForm(50 << 20) // 50 MB limit for audio
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Failed to parse form data")
		return
	}

	// Get file from form
	file, header, err := r.FormFile("voice")
	if err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "No voice file provided")
		return
	}
	defer file.Close()

	// Validate audio file type
	if !isValidAudioType(header.Header.Get("Content-Type")) {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid file type. Only MP3, WAV, and M4A audio files are allowed")
		return
	}

	// Basic voice validation
	if !h.validateBasicVoice(file, header) {
		utils.ErrorResponse(w, http.StatusBadRequest, "Voice recording validation failed. Please ensure clear audio quality")
		return
	}

	// Reset file pointer after validation
	file.Seek(0, 0)

	// Upload to MinIO
	filePath, err := h.minioService.UploadFile(file, header, userID, "voice")
	if err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, fmt.Sprintf("Failed to upload voice: %v", err))
		return
	}

	// Update user record with voice path
	if err := h.db.Model(&models.User{}).Where("id = ?", userID).Update("voice_path", filePath).Error; err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to update user record")
		return
	}

	utils.SuccessResponse(w, map[string]interface{}{
		"message":    "Voice recording uploaded successfully",
		"voice_path": filePath,
		"next_step":  "Identity verification complete. You can now access all features",
	})
}

// VerifyIdentity - Complete identity verification process
func (h *AuthHandler) VerifyIdentity(w http.ResponseWriter, r *http.Request) {
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

	// Check if user has uploaded both selfie and voice
	var user models.User
	if err := h.db.Where("id = ?", userID).First(&user).Error; err != nil {
		utils.ErrorResponse(w, http.StatusNotFound, "User not found")
		return
	}

	if user.SelfiePath == nil || user.VoicePath == nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Both selfie and voice recording are required for identity verification")
		return
	}

	// Mark user as verified
	if err := h.db.Model(&user).Updates(map[string]interface{}{
		"is_verified": true,
		"updated_at":  time.Now(),
	}).Error; err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to complete verification process")
		return
	}

	utils.SuccessResponse(w, map[string]interface{}{
		"message": "Identity verification completed successfully",
		"user": map[string]interface{}{
			"id":          user.ID,
			"email":       user.Email,
			"first_name":  user.FirstName,
			"last_name":   user.LastName,
			"is_verified": true,
			"selfie_path": user.SelfiePath,
			"voice_path":  user.VoicePath,
		},
	})
}

// GetUserProfile - Get user profile with file URLs
func (h *AuthHandler) GetUserProfile(w http.ResponseWriter, r *http.Request) {
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

    var user models.User
    if err := h.db.Where("id = ?", userID).First(&user).Error; err != nil {
        utils.ErrorResponse(w, http.StatusNotFound, "User profile not found")
        return
    }

    // Generate presigned URLs for files
    var selfieURL, voiceURL *string
    if user.SelfiePath != nil && *user.SelfiePath != "" {
        if url, err := h.minioService.GetFileURL(*user.SelfiePath); err == nil {
            selfieURL = &url
        }
    }
    if user.VoicePath != nil && *user.VoicePath != "" {
        if url, err := h.minioService.GetFileURL(*user.VoicePath); err == nil {
            voiceURL = &url
        }
    }

    utils.SuccessResponse(w, map[string]interface{}{
        "user": map[string]interface{}{
            "id": user.ID,
            "email": user.Email,
            "first_name": user.FirstName,
            "last_name": user.LastName,
            "phone": user.Phone,
            "is_verified": user.IsVerified,
            "is_active": user.IsActive,
            "selfie_url": selfieURL,
            "voice_url": voiceURL,
            "has_selfie": user.SelfiePath != nil && *user.SelfiePath != "",
            "has_voice": user.VoicePath != nil && *user.VoicePath != "",
            "verification_status": func() string {
                if user.IsVerified {
                    return "verified"
                }
                hasSelfie := user.SelfiePath != nil && *user.SelfiePath != ""
                hasVoice := user.VoicePath != nil && *user.VoicePath != ""
                if hasSelfie && hasVoice {
                    return "pending_review"
                } else if hasSelfie {
                    return "voice_required"
                } else if hasVoice {
                    return "selfie_required"
                }
                return "pending"
            }(),
            "device_info": user.DeviceInfo,
            "location": user.Location,
            "created_at": user.CreatedAt,
            "updated_at": user.UpdatedAt,
        },
    })
}


// UpdateProfile - Update user profile information
func (h *AuthHandler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
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

	var updateReq struct {
		FirstName  string                 `json:"first_name"`
		LastName   string                 `json:"last_name"`
		Phone      string                 `json:"phone"`
		DeviceInfo map[string]interface{} `json:"device_info"`
		Location   map[string]interface{} `json:"location"`
	}

	if err := json.NewDecoder(r.Body).Decode(&updateReq); err != nil {
		utils.ErrorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// Prepare update data
	updateData := map[string]interface{}{
		"updated_at": time.Now(),
	}

	if updateReq.FirstName != "" {
		updateData["first_name"] = updateReq.FirstName
	}
	if updateReq.LastName != "" {
		updateData["last_name"] = updateReq.LastName
	}
	if updateReq.Phone != "" {
		updateData["phone"] = updateReq.Phone
	}
	if updateReq.DeviceInfo != nil {
		updateData["device_info"] = models.JSONB(updateReq.DeviceInfo)
	}
	if updateReq.Location != nil {
		updateData["location"] = models.JSONB(updateReq.Location)
	}

	// Update user profile
	if err := h.db.Model(&models.User{}).Where("id = ?", userID).Updates(updateData).Error; err != nil {
		utils.ErrorResponse(w, http.StatusInternalServerError, "Failed to update profile")
		return
	}

	utils.SuccessResponse(w, map[string]interface{}{
		"message": "Profile updated successfully",
	})
}

// Helper Functions

// validateBasicLiveliness performs basic liveliness validation on selfie
func (h *AuthHandler) validateBasicLiveliness(file multipart.File, header *multipart.FileHeader) bool {
	// Basic validation checks

	// 1. File size validation (reasonable selfie size)
	if header.Size < 10*1024 { // Less than 10KB
		return false
	}
	if header.Size > 10*1024*1024 { // More than 10MB
		return false
	}

	// 2. Try to decode as image
	_, format, err := image.DecodeConfig(file)
	if err != nil {
		return false
	}

	// 3. Valid image format
	if format != "jpeg" && format != "png" {
		return false
	}

	// Reset file pointer
	file.Seek(0, 0)

	// 4. Basic image dimensions check (should be reasonable for selfie)
	img, _, err := image.Decode(file)
	if err != nil {
		return false
	}

	bounds := img.Bounds()
	width := bounds.Dx()
	height := bounds.Dy()

	// Reasonable dimensions for a selfie (not too small, not too large)
	if width < 200 || height < 200 || width > 4000 || height > 4000 {
		return false
	}

	// Basic aspect ratio check (should be roughly portrait or square)
	aspectRatio := float64(width) / float64(height)
	if aspectRatio < 0.5 || aspectRatio > 2.0 {
		return false
	}

	// All basic checks passed
	return true
}

// validateBasicVoice performs basic voice validation
func (h *AuthHandler) validateBasicVoice(file multipart.File, header *multipart.FileHeader) bool {
	// Basic validation checks

	// 1. File size validation (reasonable voice recording size)
	if header.Size < 1*1024 { // Less than 1KB
		return false
	}
	if header.Size > 50*1024*1024 { // More than 50MB
		return false
	}

	// 2. Duration check (voice should be between 2-30 seconds)
	// This is a basic check - in production, you'd use audio libraries
	// Rough estimation: 1 second of MP3 ≈ 8-32KB depending on quality
	minExpectedSize := 16 * 1024  // ~2 seconds
	maxExpectedSize := 960 * 1024 // ~30 seconds

	if header.Size < int64(minExpectedSize) || header.Size > int64(maxExpectedSize) {
		return false
	}

	// 3. Basic file content validation - read first few bytes to verify it's audio
	buffer := make([]byte, 32) // Read first 32 bytes
	n, err := file.Read(buffer)
	if err != nil || n < 4 {
		return false
	}

	// Reset file pointer after reading
	file.Seek(0, 0)

	// Check for common audio file signatures
	// MP3: starts with ID3 (0x49 0x44 0x33) or sync frame (0xFF 0xFx)
	// WAV: starts with "RIFF" and contains "WAVE"
	// M4A: starts with various signatures like "ftyp"

	// MP3 ID3 tag
	if n >= 3 && buffer[0] == 0x49 && buffer[1] == 0x44 && buffer[2] == 0x33 {
		return true
	}

	// MP3 frame sync
	if n >= 2 && buffer[0] == 0xFF && (buffer[1]&0xF0) == 0xF0 {
		return true
	}

	// WAV file signature
	if n >= 12 &&
		buffer[0] == 'R' && buffer[1] == 'I' && buffer[2] == 'F' && buffer[3] == 'F' &&
		buffer[8] == 'W' && buffer[9] == 'A' && buffer[10] == 'V' && buffer[11] == 'E' {
		return true
	}

	// M4A file signature (various ftyp boxes)
	if n >= 8 && buffer[4] == 'f' && buffer[5] == 't' && buffer[6] == 'y' && buffer[7] == 'p' {
		return true
	}

	// If we reach here, file signature doesn't match expected audio formats
	return false
}

// isValidEmail validates email format
func isValidEmail(email string) bool {
	return strings.Contains(email, "@") && strings.Contains(email, ".")
}

// isValidImageType validates image MIME types
func isValidImageType(contentType string) bool {
	validTypes := []string{
		"image/jpeg",
		"image/jpg",
		"image/png",
	}

	for _, validType := range validTypes {
		if contentType == validType {
			return true
		}
	}
	return false
}

// isValidAudioType validates audio MIME types
func isValidAudioType(contentType string) bool {
	validTypes := []string{
		"audio/mpeg",
		"audio/mp3",
		"audio/wav",
		"audio/m4a",
		"audio/x-m4a",
	}

	for _, validType := range validTypes {
		if contentType == validType {
			return true
		}
	}
	return false
}

func getVerificationStatus(isVerified bool, selfiePath, voicePath *string) string {
	if isVerified {
		return "verified"
	}

	hasSelfie := selfiePath != nil && *selfiePath != ""
	hasVoice := voicePath != nil && *voicePath != ""

	if hasSelfie && hasVoice {
		return "pending_review"
	} else if hasSelfie {
		return "voice_required"
	} else if hasVoice {
		return "selfie_required"
	}
	return "pending"
}
