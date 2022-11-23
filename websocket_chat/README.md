# 3xImplementation: WebSocket Chat Application

**Note: Architectures illustrated are for educational purposes ONLY. They do no necessarily follow best practices and are NOT suitable for production.**

## Requirements
- [ ] AWS account with programmatic access, i.e., `ACCESS_KEY_ID` and `SECRET_ACCESS_KEY`
- [ ] GitHub account with the frontend application source repository cloned and a personal access token that provides access to the repository

## Notes
- [ ] HTTP endpoint for WebSocket API in API Gateway: Integration requests have to be set up to deliver the `connectionId` to the backend endpoint
- [ ] Callback URL for WebSocket API must be configured for the Go SDK using an EndpointResolver

## References
- [https://docs.amplify.aws/guides/hosting/nextjs/q/platform/js/#dynamic-routes](https://docs.amplify.aws/guides/hosting/nextjs/q/platform/js/#dynamic-routes)
