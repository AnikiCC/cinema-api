package models

type User struct {
	Name     string  `json:"name"`
	Mail     string  `json:"mail"`
	Password string  `json:"password"`
	Role     string  `json:"role"`
	Rating   float64 `json:"rating"`
}

type Login struct {
	ID       int     `json:"id"`
	Name     string  `json:"name"`
	Mail     string  `json:"mail"`
	Password string  `json:"password"`
	Role     string  `json:"role"`
	Rating   float64 `json:"rating"`
}

type Movie struct {
	Title       string   `json:"title"`
	Description string   `json:"description"`
	Genres      []string `json:"genres"`
	Rating      float64  `json:"rating"`
	ReviewCount int      `json:"review_count"`
}

type CriticReview struct {
	ID      int     `json:"id"`
	Title   string  `json:"title"`
	Text    string  `json:"text"`
	Rating  float64 `json:"rating"`
	MovieID int     `json:"movie_id"`
	UserID  int     `json:"user_id"`
}

type UserReview struct {
	ID      int     `json:"id"`
	Text    string  `json:"text"`
	Rating  float64 `json:"rating"`
	MovieID int     `json:"movie_id"`
	UserID  int     `json:"user_id"`
}

type Article struct {
	ID     int      `json:"id"`
	Title  string   `json:"title"`
	Text   string   `json:"text"`
	Tags   []string `json:"tags"`
	UserID int      `json:"user_id"`
}

type FilteredReview struct {
	ReviewText string  `json:"review_text"`
	Stars      float64 `json:"stars"`
	MovieTitle string  `json:"movie_title"`
	UserName   string  `json:"user_name"`
}
