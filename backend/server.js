require("dotenv").config();

const express = require("express");
const pool = require("./src/config/database");

const app = express();

app.use(express.json());

app.get("/api/test-db", async (req, res) => {
    try {
        const result = await pool.query(
            "SELECT NOW() AS server_time"
        );

        res.json({
            success: true,
            message: "Connexion PostgreSQL réussie",
            data: result.rows[0]
        });

    } catch (error) {
        console.error(error.message);

        res.status(500).json({
            success: false,
            message: "Erreur de connexion PostgreSQL"
        });
    }
});

app.listen(process.env.PORT || 5000, () => {
    console.log("Serveur démarré sur le port 5000");
});