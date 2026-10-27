#![allow(dead_code)]

use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::{PgPool, postgres::PgPoolOptions};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize)]
pub struct Pie {
    pub id: Uuid,
    pub prediction: String,
    pub created_at: DateTime<Utc>,
}

pub async fn connect(database_url: &str) -> Result<PgPool, sqlx::Error> {
    PgPoolOptions::new()
        .max_connections(5)
        .connect(database_url)
        .await
}

pub async fn list_pies(pool: &PgPool) -> Result<Vec<Pie>, sqlx::Error> {
    sqlx::query_as!(
        Pie,
        "SELECT id, prediction, created_at FROM pies ORDER BY created_at"
    )
    .fetch_all(pool)
    .await
}

pub async fn random_pie(pool: &PgPool) -> Result<Pie, sqlx::Error> {
    sqlx::query_as!(
        Pie,
        "SELECT id, prediction, created_at FROM pies ORDER BY random() LIMIT 1"
    )
    .fetch_one(pool)
    .await
}

pub async fn insert_pie(pool: &PgPool, prediction: &str) -> Result<Pie, sqlx::Error> {
    sqlx::query_as!(
        Pie,
        "INSERT INTO pies (prediction) VALUES ($1) RETURNING id, prediction, created_at",
        prediction
    )
    .fetch_one(pool)
    .await
}
