# 3xImplementation: WebSocket Chat Application

**Note: Architectures illustrated are for educational purposes ONLY. They do no necessarily follow best practices and are NOT suitable for production.**

## Requirements
- [ ] AWS account with programmatic access, i.e., `ACCESS_KEY_ID` and `SECRET_ACCESS_KEY`
- [ ] GitHub account with the frontend application source repository cloned and a personal access token that provides access to the repository

## Notes
- [ ] HTTP endpoint for WebSocket API in API Gateway: Integration requests have to be set up to deliver the `connectionId` to the backend endpoint
- [ ] Callback URL for WebSocket API must be configured for the Go SDK using an EndpointResolver
## Gotchas
- [ ] IAM Service Role must be created for AWS API GW to write to CW Logs. See https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html
- [ ] Default integration response must be configured for WebSocket API routes that use integration (non-proxy) HTTP backend (otherwise nothing is returned).
## Problems
- [ ] Use stageVariables in aws_apigatewayv2_integration

## References
- [https://docs.amplify.aws/guides/hosting/nextjs/q/platform/js/#dynamic-routes](https://docs.amplify.aws/guides/hosting/nextjs/q/platform/js/#dynamic-routes)
