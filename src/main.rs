mod db;

use std::env;

#[tokio::main]
async fn main() -> Result<(), sqlx::Error> {
    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let pool = db::connect(&database_url).await?;

    let pies = db::list_pies(&pool).await?;
    for pie in pies {
        println!("{} | {} | {}", pie.id, pie.created_at, pie.prediction);
    }

    Ok(())
}
