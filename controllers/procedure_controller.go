package controllers

import (
	"cinema-api/db"
	"cinema-api/models"
	"log"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/lib/pq"
)

func AddUserReview(c *gin.Context) {
	var Review models.UserReview
	if err := c.ShouldBindJSON(&Review); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	_, err := db.DB.Exec(
		"CALL add_user_review($1, $2, $3, $4)",
		Review.MovieID, Review.UserID, Review.Text, Review.Rating,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Отзыв успешно добавлен"})
}

func AddArticle(c *gin.Context) {
	var article models.Article
	if err := c.ShouldBindJSON(&article); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	_, err := db.DB.Exec(
		"CALL add_article($1, $2, $3)",
		article.UserID, article.Title, article.Text,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Статья успешно добавлена"})
}

func DeleteUserReview(c *gin.Context) {
	reviewID, _ := strconv.Atoi(c.Param("review_id"))
	userID, _ := strconv.Atoi(c.Param("user_id"))

	_, err := db.DB.Exec(
		"CALL delete_user_review($1, $2)",
		reviewID, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Отзыв успешно удален"})
}

func DeleteArticle(c *gin.Context) {
	articleID, _ := strconv.Atoi(c.Param("article_id"))
	userID, _ := strconv.Atoi(c.Param("user_id"))

	_, err := db.DB.Exec(
		"CALL delete_article($1, $2)",
		articleID, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Статья успешно удалена"})
}

func GetUserStatistics(c *gin.Context) {
	userID, _ := strconv.Atoi(c.Param("user_id"))

	var reviewCount, articleCount int

	err := db.DB.QueryRow(
		"CALL get_user_statistics($1, $2, $3)",
		userID,
		&reviewCount,
		&articleCount,
	).Scan(&reviewCount, &articleCount)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"review_count":  reviewCount,
		"article_count": articleCount,
	})
}

func AddCriticReview(c *gin.Context) {
	var review models.CriticReview
	if err := c.ShouldBindJSON(&review); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	_, err := db.DB.Exec(
		"CALL add_critic_review($1, $2, $3, $4, $5)",
		review.MovieID, review.UserID, review.Title, review.Text, review.Rating,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Отзыв критика успешно добавлен"})
}

func DeleteCriticReview(c *gin.Context) {
	reviewID, _ := strconv.Atoi(c.Param("review_id"))
	userID, _ := strconv.Atoi(c.Param("user_id"))

	_, err := db.DB.Exec(
		"CALL delete_critic_review($1, $2)",
		reviewID, userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Отзыв критика успешно удален"})
}

func SaveMovieToDatabase(c *gin.Context) {
	var movie models.Movie
	if err := c.ShouldBindJSON(&movie); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	_, err := db.DB.Exec(
		"CALL save_movie($1, $2, $3, $4, $5)",
		movie.Title, movie.Description, pq.Array(movie.Genres), movie.Rating, movie.ReviewCount,
	)

	if err != nil {
		log.Println("Failed to execute save_movie:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Фильм успешно добален"})
}
