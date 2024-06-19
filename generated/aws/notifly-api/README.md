## notifly-api

```
terraform init
terraform import aws_cognito_user_pool.user_pool ap-northeast-2_KzU5qgIbi
terraform import aws_cognito_user_pool_client.web_user_pool_client ap-northeast-2_KzU5qgIbi/mijj78tf66mleq1slmh0c02eh
terraform import aws_cognito_user_pool.web_user_pool ap-northeast-2_i9p41Hw81
terraform import aws_cognito_user_pool_client.web_user_pool_client ap-northeast-2_i9p41Hw81/3q5ka4e8kd8nk1bo0d9p75d1nt
terraform import aws_cognito_user_pool.user_pool_dev ap-northeast-2_5br5wFCtJ
terraform import aws_cognito_user_pool_client.user_pool_dev_client ap-northeast-2_5br5wFCtJ/3hhmnrtue812j653s33nc2e769
terraform import aws_cognito_user_pool.web_user_pool_dev ap-northeast-2_Sfvlps3oh
terraform import aws_cognito_user_pool_client.web_user_pool_dev_client ap-northeast-2_Sfvlps3oh/2jlk64cqb9hh77ice3erbgceud
terraform import aws_cognito_user_pool.payment_user_pool ap-northeast-2_retPXtocf
terraform import aws_cognito_user_pool_client.web_user_pool_client ap-northeast-2_retPXtocf/7ps3bi3pq5ljmu2m5qua1tvp0l
```

```
curl -v GET "https://t8uwvi810g.execute-api.ap-northeast-2.amazonaws.com/debug"
```

Result:

```
{"message":"Good day, you of World.","input":{"version":"2.0","routeKey":"GET /debug","rawPath":"/debug","rawQueryString":"","headers":{"accept":"*/*","content-length":"0","host":"t8uwvi810g.execute-api.ap-northeast-2.amazonaws.com","user-agent":"curl/7.77.0","x-amzn-trace-id":"Root=1-63d11447-14cd0c96003af923393938bd","x-forwarded-for":"203.233.2.154","x-forwarded-port":"443","x-forwarded-proto":"https"},"requestContext":{"accountId":"702197142747","apiId":"t8uwvi810g","domainName":"t8uwvi810g.execute-api.ap-northeast-2.amazonaws.com","domainPrefix":"t8uwvi810g","http":{"method":"GET","path":"/debug","protocol":"HTTP/1.1","sourceIp":"203.233.2.154","userAgent":"curl/7.77.0"},"requestId":"fTAbLiQlIE0EJbg=","routeKey":"GET /debug","stage":"$default","time":"25/Jan/2023:11:36:39 +0000","timeEpoch":1674646599368},"isBase64Encoded":false}
```
