package main

import (
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()

	// Serving the existing docs
	r.StaticFile("/", "/app/sha257sum/docs/index.html")
	r.Static("/docs", "/app/sha257sum/docs")

	// Pkgsite-inspired v1beta/api
	r.GET("/v1beta/api", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "Welcome to the sha257sum Pkgsite-inspired API",
			"documentation": "https://pkg.go.dev/v1beta/api",
			"endpoints": []string{
				"/v1beta/api/implementations",
				"/v1beta/api/hash/:lang/:input",
			},
		})
	})

	r.GET("/v1beta/api/implementations", func(c *gin.Context) {
		files, err := os.ReadDir("/app/sha257sum/sha257")
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		var impls []string
		for _, f := range files {
			if !f.IsDir() && strings.HasPrefix(f.Name(), "sha257sum.") {
				ext := filepath.Ext(f.Name())
				if ext != "" {
					impls = append(impls, ext[1:])
				}
			}
		}
		c.JSON(http.StatusOK, gin.H{"implementations": impls})
	})

	r.GET("/v1beta/api/hash/:lang/:input", func(c *gin.Context) {
		lang := c.Param("lang")
		input := c.Param("input")

		var cmd *exec.Cmd
		switch lang {
		case "py", "python":
			cmd = exec.Command("python3", "sha257sum.py", input)
		case "go":
			cmd = exec.Command("go", "run", "sha257sum.go", input)
		case "sh", "bash":
			cmd = exec.Command("./sha257sum.sh", input)
		default:
			c.JSON(http.StatusNotFound, gin.H{"error": "implementation not supported via API yet"})
			return
		}

		cmd.Dir = "/app/sha257sum/sha257"
		out, err := cmd.CombinedOutput()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error(), "output": string(out)})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"lang":   lang,
			"input":  input,
			"hash":   strings.TrimSpace(string(out)),
		})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	fmt.Printf("sha257sum API listening on port %s\n", port)
	r.Run(":" + port)
}
