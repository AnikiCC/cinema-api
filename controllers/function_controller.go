package controllers

import (
	"cinema-api/db"
	"cinema-api/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/lib/pq"
)

func GetAvgCriticRating(c *gin.Context) {
	movieID := c.Param("id")

	var avgRating float64
	err := db.DB.QueryRow("SELECT get_avg_critic_rating($1)", movieID).Scan(&avgRating)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"avg_critic_rating": avgRating})
}

func GetAvgUserRating(c *gin.Context) {
	movieID := c.Param("id")

	var avgRating float64
	err := db.DB.QueryRow("SELECT get_avg_user_rating($1)", movieID).Scan(&avgRating)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"avg_user_rating": avgRating})
}

func GetMovieInfo(c *gin.Context) {
	movieID := c.Param("id")

	var movie models.Movie

	err := db.DB.QueryRow("SELECT * FROM get_movie_info($1)", movieID).
		Scan(&movie.Title, &movie.Description, pq.Array(&movie.Genres), &movie.Rating, &movie.ReviewCount)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, movie)
}

func UpdateUserRating(c *gin.Context) {
	userID := c.Param("id")

	_, err := db.DB.Exec("SELECT update_user_rating($1)", userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Рейтинг пользователя успешно обновлен"})
}
