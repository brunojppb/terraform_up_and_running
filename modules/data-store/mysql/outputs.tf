output "address" {
  value = aws_db_instance.example.address
  description = "Connect to database at this address"
}

output "port" {
  value = aws_db_instance.example.port
  description = "Port the database is listening to"
}