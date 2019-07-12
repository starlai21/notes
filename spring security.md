# Spring Security



以mall 工程中的 mall-admin jwt 方式授权认证为例

```SecurityConfig extends WebSecurityConfigurerAdapter```

httpSecurity.addFilterBefore(jwtAuthenticationTokenFilter)

加入过滤器



```java
JwtAuthenticationTokenFilter extends OncePerRequestFilter
```

doFilterInternal

1.从header 中获取 token

2.从 token 中解析出 username

3.如果 username 不为空，则调用userDetailService 的 loadUserByUsername 获取UserDetails， 验证token 的有效性

4.如果 token 有效， ``` UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());```

``` SecurityContextHolder.getContext().setAuthentication(authentication);```

将用户拥有权限写入本次会话