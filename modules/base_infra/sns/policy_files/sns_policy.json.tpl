{
    "Version": "2008-10-17",
    "Id": "__default_policy_ID",
    "Statement": [
        {
            "Sid":  "One",
            "Effect": "Allow",
            "Action": ["sns:Publish"],
            "Resource": "${resource}",
            "Principal": {
                "Service": [
                    "events.amazonaws.com", 
                    "budgets.amazonaws.com", 
                    "rds.amazonaws.com", 
                    "s3.amazonaws.com"
                ]
            }
        },
        {
            "Sid":  "Two",
            "Effect": "Allow",
            "Action": ["sns:Publish"],
            "Resource": "${resource}",
            "Principal": { "AWS": "*" },
            "Condition": {
                "StringEquals": {
                     "AWS:SourceOwner": "${account_id}"
                }
            }
        }
    ]
}