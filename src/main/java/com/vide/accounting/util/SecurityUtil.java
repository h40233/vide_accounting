package com.vide.accounting.util;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;

import java.util.UUID;

public class SecurityUtil {

    /**
     * 從 Spring Security Context 中取出目前驗證通過的 Supabase user_id (UUID 格式)
     * Jwt JWT 裡面的 'sub' claim 就是 user_id。
     */
    public static UUID getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof Jwt jwt) {
            String sub = jwt.getSubject();
            if (sub != null && !sub.isBlank()) {
                return UUID.fromString(sub);
            }
        }
        throw new IllegalStateException("無法取得當前使用者資訊 (未授權或無效的 JWT 結構)");
    }
}
