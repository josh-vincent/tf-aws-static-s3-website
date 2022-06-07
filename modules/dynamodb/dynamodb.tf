resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "LinkedInOffers"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "Id"
#  range_key      = "Amount"

  attribute {
    name = "Id"
    type = "S"
  }

#  attribute {
#    name = "Amount"
#    type = "N"
#  }

#  attribute {
#    name = "TopAmount"
#    type = "N"
#  }
#
#  attribute {
#    name = "BottomAmount"
#    type = "N"
#  }
#
#  attribute {
#    name = "Type"
#    type = "S"
#  }
#
#  attribute {
#    name = "JobTitle"
#    type = "S"
#  }
#
#  attribute {
#    name = "Categories"
#    type = "S"
#  }

  tags = yamldecode(templatefile("${path.root}/files/tags/tags.yaml", {}))
}

output dynamodb_table_name {
  value = aws_dynamodb_table.basic-dynamodb-table.name
}

output dynamodb_table_arn {
  value = aws_dynamodb_table.basic-dynamodb-table.arn
}

# Example Item
resource "aws_dynamodb_table_item" "example" {
  table_name = aws_dynamodb_table.basic-dynamodb-table.name
  hash_key   = aws_dynamodb_table.basic-dynamodb-table.hash_key

  item = <<ITEM
   {
    "Id": {
      "S": "1"
    },
    "Amount": {
      "N": "150000"
    }
  }
  ITEM
}
