package controllers

import (
	"cinema-api/db"
	"cinema-api/models"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/lib/pq"
)

func GetMovieReport(c *gin.Context) {
	var movies []models.Movie
	rows, err := db.DB.Query(
		"SELECT title, rating, genres, review_count FROM movie_report",
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	for rows.Next() {
		var movie models.Movie

		err := rows.Scan(&movie.Title, &movie.Rating, pq.Array(&movie.Genres), &movie.ReviewCount)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		movies = append(movies, movie)
	}

	c.JSON(http.StatusOK, movies)
}

func GetUserReport(c *gin.Context) {
	var users []models.User
	rows, err := db.DB.Query(
		"SELECT name, mail, role, rating FROM user_report",
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	for rows.Next() {
		var user models.User
		err := rows.Scan(&user.Name, &user.Mail, &user.Role, &user.Rating)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		users = append(users, user)
	}

	c.JSON(http.StatusOK, users)
}

func GetFilteredReviews(c *gin.Context) {
	var reviews []models.FilteredReview
	rows, err := db.DB.Query(
		"SELECT review_text, stars, movie_title, user_name FROM filtered_reviews",
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer rows.Close()

	for rows.Next() {
		var review models.FilteredReview
		err := rows.Scan(&review.ReviewText, &review.Stars, &review.MovieTitle, &review.UserName)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		reviews = append(reviews, review)
	}

	c.JSON(http.StatusOK, reviews)
}
