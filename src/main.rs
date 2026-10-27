mod db;

use std::env;

use axum::{Json, Router, extract::State, http::StatusCode, routing::get};
use sqlx::PgPool;

use db::Pie;

#[tokio::main]
async fn main() {
    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let app_addr = env::var("APP_ADDR").expect("APP_ADDR must be set");

    let pool = db::connect(&database_url)
        .await
        .expect("failed to connect to database");

    let app = Router::new().route("/pie", get(get_pie)).with_state(pool);

    let listener = tokio::net::TcpListener::bind(&app_addr)
        .await
        .expect("failed to bind APP_ADDR");

    axum::serve(listener, app).await.expect("server error");
}

async fn get_pie(State(pool): State<PgPool>) -> Result<Json<Pie>, (StatusCode, String)> {
    db::random_pie(&pool)
        .await
        .map(Json)
        .map_err(|err| (StatusCode::INTERNAL_SERVER_ERROR, err.to_string()))
}
