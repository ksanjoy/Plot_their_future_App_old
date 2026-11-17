package com.plottheirfuture.plottheirfuture_backend.dto;

import com.plottheirfuture.plottheirfuture_backend.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {

    private String token;

    @Builder.Default
    private String tokenType = "Bearer";

    private Long expiresIn;

    private User user;

    private Boolean isExistingUser;

    private Boolean hasActiveMarriageRegistration;

    private List<String> accessibleWeddings;

    private String message;
}

