package main

import (
	"cinema-api/db"
	"cinema-api/routes"
	"fmt"

	"github.com/gin-gonic/gin"
)

func main() {
	db.Initialize()
	defer db.Close()

	r := gin.Default()

	r.Static("/public", "./public")

	r.GET("/", func(c *gin.Context) {
		c.File("./public/index.html")
	})

	r.GET("/login", func(c *gin.Context) {
		c.File("./public/login.html")
	})

	r.GET("/welcome", func(c *gin.Context) {
		c.File("./public/welcome.html")
	})

	routes.SetupViewRoutes(r)      // Роуты для отображения
	routes.SetupProcedureRoutes(r) // Роуты для работы с процедурами
	routes.SetupFunctionRoutes(r)  // Роуты для функций
	routes.SetupAuthRoutes(r)      // Роуты для аутентификации

	err := r.Run(":8080")
	if err != nil {
		fmt.Println("Ошибка запуска сервера: ", err)
	}
}
