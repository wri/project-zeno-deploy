# Import existing RDS instance as a data source
data "aws_db_instance" "zeno-db" {
    db_instance_identifier = "zeno-db"
}
