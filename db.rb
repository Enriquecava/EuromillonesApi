require "pg"
require "dotenv/load"

DB = PG.connect(
  host: ENV['PG_HOST'],
  port: ENV['PG_PORT'],
  dbname: ENV['PG_DB'],
  user: ENV['PG_USER'],
  password: ENV['PG_PASSWORD'],
  sslmode: 'require'
)
