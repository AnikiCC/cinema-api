package controllers

import (
	"cinema-api/db"
	"cinema-api/models"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/dgrijalva/jwt-go"
	"golang.org/x/crypto/bcrypt"
)

var secretKey = []byte("secretKey")

func RegisterUser(c *gin.Context) {
	var user models.Login
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(user.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка хеширования пароля"})
		return
	}
	user.Password = string(hashedPassword)

	_, err = db.DB.Exec("INSERT INTO Users (name, mail, password, role) VALUES ($1, $2, $3, $4)", user.Name, user.Mail, user.Password, user.Role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка сохранения пользователя"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Registration successful", "redirect": "/login"})
}

func LoginUser(c *gin.Context) {
	var loginData models.Login
	if err := c.ShouldBindJSON(&loginData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Неверный ввод"})
		return
	}

	var user models.Login
	err := db.DB.QueryRow("SELECT id, name, mail, password, role FROM Users WHERE mail = $1", loginData.Mail).Scan(&user.ID, &user.Name, &user.Mail, &user.Password, &user.Role)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неверный адрес электронной почты или пароль"})
		return
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(loginData.Password))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Неверный адрес электронной почты или пароль"})
		return
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": user.ID,
		"role":    user.Role,
		"name":    user.Name,
		"exp":     time.Now().Add(time.Hour * 24).Unix(),
	})
	tokenString, err := token.SignedString(secretKey)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка генерации токена"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message":  "Login successful",
		"token":    tokenString,
		"redirect": "/welcome",
	})
}

func LogoutUser(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Успешно вышел из системы"})
}
