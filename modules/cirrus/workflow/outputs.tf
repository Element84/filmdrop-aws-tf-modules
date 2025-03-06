output "state_machine_arn" {
  value = aws_sfn_state_machine.workflow.arn
}

output "state_machine_role_arn" {
  value = aws_iam_role.workflow_machine.arn
}
