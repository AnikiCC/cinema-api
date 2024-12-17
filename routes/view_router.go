package routes

import (
	"cinema-api/controllers"

	"github.com/gin-gonic/gin"
)

func SetupViewRoutes(r *gin.Engine) {
	r.GET("/movie_report", controllers.GetMovieReport)
	r.GET("/user_report", controllers.GetUserReport)
	r.GET("/filtered_reviews", controllers.GetFilteredReviews)
}
