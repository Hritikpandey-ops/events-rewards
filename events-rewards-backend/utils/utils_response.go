package utils

import (
    "encoding/json"
    "net/http"
    "regexp"
)

type APIResponse struct {
    Success bool        `json:"success"`
    Data    interface{} `json:"data,omitempty"`
    Error   string      `json:"error,omitempty"`
    Message string      `json:"message,omitempty"`
}

func SuccessResponse(w http.ResponseWriter, data interface{}) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)

    response := APIResponse{
        Success: true,
        Data:    data,
    }

    json.NewEncoder(w).Encode(response)
}

func ErrorResponse(w http.ResponseWriter, statusCode int, message string) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(statusCode)

    response := APIResponse{
        Success: false,
        Error:   message,
    }

    json.NewEncoder(w).Encode(response)
}

func MessageResponse(w http.ResponseWriter, message string) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)

    response := APIResponse{
        Success: true,
        Message: message,
    }

    json.NewEncoder(w).Encode(response)
}

func IsValidEmail(email string) bool {
    emailRegex := `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
    re := regexp.MustCompile(emailRegex)
    return re.MatchString(email)
}
