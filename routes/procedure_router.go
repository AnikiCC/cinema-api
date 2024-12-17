package routes

import (
	"cinema-api/controllers"

	"github.com/gin-gonic/gin"
)

func SetupProcedureRoutes(r *gin.Engine) {
	r.POST("/reviews", controllers.AddUserReview)
	r.DELETE("/reviews/:review_id/:user_id", controllers.DeleteUserReview)
	r.POST("/articles", controllers.AddArticle)
	r.DELETE("/articles/:article_id/:user_id", controllers.DeleteArticle)
	r.GET("/users/:user_id/stats", controllers.GetUserStatistics)
	r.POST("/critic_reviews", controllers.AddCriticReview)
	r.DELETE("/critic_reviews/:review_id/:user_id", controllers.DeleteCriticReview)
	r.POST("/save_movie", controllers.SaveMovieToDatabase)
}
