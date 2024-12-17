package routes

import (
	"cinema-api/controllers"

	"github.com/gin-gonic/gin"
)

func SetupFunctionRoutes(router *gin.Engine) {
	functionGroup := router.Group("/functions")
	{
		functionGroup.GET("/avg_critic_rating/:id", controllers.GetAvgCriticRating)
		functionGroup.GET("/avg_user_rating/:id", controllers.GetAvgUserRating)
		functionGroup.GET("/movie_info/:id", controllers.GetMovieInfo)
		functionGroup.PUT("/update_user_rating/:id", controllers.UpdateUserRating)

	}
}
