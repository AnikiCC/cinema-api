package routes

import (
	"cinema-api/controllers"
	"cinema-api/middleware"

	"github.com/gin-gonic/gin"
)

func SetupAuthRoutes(r *gin.Engine) {
	authGroup := r.Group("/auth")
	{
		authGroup.POST("/register", controllers.RegisterUser)
		authGroup.POST("/login", controllers.LoginUser)
		authGroup.GET("/logout", controllers.LogoutUser)
	}

	r.GET("/protected", middleware.ValidateToken, func(c *gin.Context) {
		c.JSON(200, gin.H{"message": "Вы авторизованы"})
	})
}
